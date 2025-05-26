-- Handles wikilinks, embeds, callouts, and tags

-- Handle [[wikilinks]] and [[link|alias]]
function Link(el)
	if el.title == "wikilink" then
		-- Extract alias if present
		local target = el.target
		local alias = el.content

		if target:match("|") then
			local parts = {}
			for part in target:gmatch("[^|]+") do
				table.insert(parts, part)
			end
			target = parts[1]
			if #parts > 1 then
				alias = pandoc.Str(parts[2])
			end
		end

		-- Convert to standard link
		return pandoc.Link(alias, target .. ".html", "", { class = "internal-link" })
	end
	return el
end

-- Handle ![[embeds]]
function Image(el)
	if el.src:match("^!%[%[") then
		local embed = el.src:match("!%[%[(.+)%]%]")
		if embed then
			-- Check if it's an image
			if embed:match("%.png$") or embed:match("%.jpg$") or embed:match("%.jpeg$") then
				return pandoc.Image(el.caption, embed, el.title, el.attr)
			else
				-- It's a note embed - read and include content
				local file = io.open(embed .. ".md", "r")
				if file then
					local content = file:read("*all")
					file:close()
					return pandoc.Div(pandoc.read(content).blocks, { class = "embedded-note" })
				end
			end
		end
	end
	return el
end

-- Handle callouts: > [!note] Title
function BlockQuote(el)
	local first = el.content[1]
	if first and first.t == "Para" then
		local first_str = pandoc.utils.stringify(first)
		local callout_type, title = first_str:match("^%[!(%w+)%]%s*(.*)$")

		if callout_type then
			-- Remove the callout marker from content
			table.remove(el.content, 1)
			if title and title ~= "" then
				table.insert(el.content, 1, pandoc.Header(6, title))
			end

			-- Return styled div
			return pandoc.Div(el.content, {
				class = "callout callout-" .. callout_type:lower()
			})
		end
	end
	return el
end

-- Handle #tags
function Str(el)
	local tag = el.text:match("^#([%w%-_/]+)$")
	if tag then
		return pandoc.Span(el.text, { class = "tag" })
	end
	return el
end
