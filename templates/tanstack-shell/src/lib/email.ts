import { Resend } from "resend";

// email is a Resend instance with the API key configured.
//
// Usage Examples:
//
//  const { data, error } = await resend.emails.send({
//    from: "Acme <onboarding@resend.dev>",
//    to: ["delivered@resend.dev"],
//    subject: "hello world",
//    html: "<strong>it works!</strong>",
//  });
export const email = new Resend(process.env.RESEND_API_KEY ?? "");
