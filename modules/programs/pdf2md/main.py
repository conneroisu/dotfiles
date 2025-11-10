#!/usr/bin/env python3
import os
import uuid
import sys
import asyncio
import io
import img2pdf
from PIL import Image
from desktop_notifier import DesktopNotifier
from pathlib import Path

PROMPT = '<image>\n<|grounding|>Convert the document to obsidian markdown.'
API_KEY_KEY = "OCR_API_KEY"
API_ENDPOINT_KEY = "OCR_API_ENDPOINT"


def pdf_to_images(
    pdf_path: str,
    dpi: int = 144,
) -> list[Image]:
    """Convert a PDF to a list of images.

    Args:
        pdf_path: path to the PDF file
        dpi: DPI of the output images
        image_format: format of the output images

    Returns:
        
    """
    import fitz
    images = []
    
    pdf_document = fitz.open(pdf_path)
    
    zoom = dpi / 72.0
    matrix = fitz.Matrix(zoom, zoom)
    
    for page_num in range(pdf_document.page_count):
        page = pdf_document[page_num]
        pixmap = page.get_pixmap(matrix=matrix, alpha=False)
        Image.MAX_IMAGE_PIXELS = None
        img_data = pixmap.tobytes("png")
        img = Image.open(io.BytesIO(img_data))
        images.append(img)
    
    pdf_document.close()
    return images


def img_to_pdf(
    pil_images: list[Image],
    output_path: str
):
    if not pil_images:
        return
    image_bytes_list = []
    for img in pil_images:
        if img.mode != 'RGB':
            img = img.convert('RGB')
        img_buffer = io.BytesIO()
        img.save(img_buffer, format='JPEG', quality=95)
        img_bytes = img_buffer.getvalue()
        image_bytes_list.append(img_bytes)
    try:
        pdf_bytes = img2pdf.convert(image_bytes_list)
        if pdf_bytes is None:
            raise Exception("Failed to convert images to PDF")
        with open(output_path, "wb") as f:
            f.write(pdf_bytes)
    except Exception as e:
        print(f"error: {e}")


async def send_notification(
    file_path: str,
) -> None:
    """Send a notification with the given file path.

    Args:
        file_path: path to the file to send
    """
    notifier = DesktopNotifier()

    await notifier.send(
        title=f"pdf2md converted {file_path}",
        message="result saved to ~/Downloads/test.pdf",
    )


def get_env(key: str) -> str:
    """Get the value of an environment variable.

    Args:
        key: name of the environment variable

    Returns:
        value of the environment variable
    """
    try:
        result = next(line.split("=", 1)[1].strip() for line in open(os.path.expanduser("~/dotfiles/.env")) if line.startswith(f"{key}="))
    except StopIteration:
        raise ValueError(f"Environment variable {key} not found")
    except Exception as e:
        raise ValueError(f"Error reading environment variable {key}: {e}")
    return result


async def img_to_md(
    img: Image,
) -> str:
    """Convert an image to Markdown using OpenAI's API.

    Args:
        img: the image to convert
        prompt: the prompt to use for the conversion
        api_key: the API key for OpenAI
        model: the model to use for the conversion

    Returns:
        the converted Markdown
    """

    import base64
    from openai import OpenAI

    client = OpenAI(
        api_key=get_env(API_KEY_KEY),
        base_url=get_env(API_ENDPOINT_KEY),
        timeout=3600
    )

    image_name = str(uuid.uuid4()) + ".png"
    img.save(image_name, format='PNG')
    image_data = open(image_name, 'rb').read()
    
    base64_string = base64.b64encode(image_data).decode('utf-8')
    image_data_url = f"data:image/png;base64,{base64_string}"

    messages = [
        {
            "role": "user",
            "content": [
                {
                    "type": "image_url",
                    "image_url": {
                        "url": image_data_url
                    }
                },
                {
                    "type": "text",
                    "text": PROMPT
                }
            ]
        }
    ]

    response = client.chat.completions.create(
        model="deepseek-ai/DeepSeek-OCR",
        messages=messages,
        max_tokens=2048,
        temperature=0.0,
        extra_body={
            "skip_special_tokens": False,
            "vllm_xargs": {  # args used to control custom logits processor
                "ngram_size": 40,
                "window_size": 90,
                "whitelist_token_ids": [128821, 128822],  # whitelist: <td>, </td>
            },
        },
    )

    return response.choices[0].message.content


def re_match(text):
    pattern = r'(<\|ref\|>(.*?)<\|/ref\|><\|det\|>(.*?)<\|/det\|>)'
    matches = re.findall(pattern, text, re.DOTALL)


    mathes_image = []
    mathes_other = []
    for a_match in matches:
        if '<|ref|>image<|/ref|>' in a_match[0]:
            mathes_image.append(a_match[0])
        else:
            mathes_other.append(a_match[0])
    return matches, mathes_image, mathes_other

def extract_coordinates_and_label(ref_text: str, image_width: int, image_height: int):
    try:
        label_type = ref_text[1]
        cor_list = eval(ref_text[2])
    except Exception as e:
        print(e)
        return None

    return (label_type, cor_list)



async def main():
    if len(sys.argv) < 2:
        print("Usage: pdf2md <file_path>")
        return
    file_path = Path(sys.argv[1])
    if not file_path.is_file():
        raise ValueError(f"File {file_path} does not exist")
    print("Converting PDF to images...")
    images = pdf_to_images(file_path)
    print("Converting images to Markdown...")
    markdown: list[str] = []
    for image in images:
        content = await img_to_md(image)
        matches, mathes_image, mathes_other = re_match(content)
        
        markdown.append(content)


    final_markdown = ""
    for i, md in enumerate(markdown):
        # print(f"Image {i+1}:")
        # print(md)
        final_markdown += f"\n<!-- Page {i+1} --->\n"
        final_markdown += md
        final_markdown += "\n\n"
        

    


    await send_notification(file_path.with_suffix(".md"))

if __name__ == "__main__":
    asyncio.run(main())
