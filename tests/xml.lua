-- A small XML reader for WoW UI files (enough for Outfitter's .xml files).
-- Returns a tree of nodes: { tag = "Frame", attr = { name = "..." }, children = { ... }, text = "..." }

local XML = {}

local function DecodeEntities(s)
	return (s:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&quot;", '"'):gsub("&apos;", "'"):gsub("&amp;", "&"))
end

local function ParseAttributes(s)
	local attr = {}
	for key, quote, value in s:gmatch('([%w_:%-]+)%s*=%s*(["\'])(.-)%2') do
		attr[key] = DecodeEntities(value)
	end
	return attr
end

function XML.Parse(source, fileName)
	source = source:gsub("\r\n", "\n")
	local root = { tag = "#root", attr = {}, children = {} }
	local stack = { root }
	local pos = 1
	local len = #source
	while pos <= len do
		local lt = source:find("<", pos, true)
		local top = stack[#stack]
		if not lt then
			break
		end
		if lt > pos then
			top.text = (top.text or "") .. DecodeEntities(source:sub(pos, lt - 1))
		end
		if source:sub(lt, lt + 3) == "<!--" then
			local close = source:find("-->", lt + 4, true)
			assert(close, fileName .. ": unclosed comment")
			pos = close + 3
		elseif source:sub(lt, lt + 8) == "<![CDATA[" then
			local close = source:find("]]>", lt + 9, true)
			assert(close, fileName .. ": unclosed CDATA")
			top.text = (top.text or "") .. source:sub(lt + 9, close - 1)
			pos = close + 3
		elseif source:sub(lt, lt + 1) == "<?" then
			pos = source:find("?>", lt, true) + 2
		elseif source:sub(lt, lt + 1) == "</" then
			local gt = source:find(">", lt, true)
			local tag = source:sub(lt + 2, gt - 1):match("^%s*([%w_:]+)")
			local node = table.remove(stack)
			if node.tag ~= tag then
				error(string.format("%s: closing </%s> does not match <%s>", fileName, tostring(tag), tostring(node.tag)))
			end
			pos = gt + 1
		else
			-- Find the end of the tag, skipping quoted attribute values
			local i = lt + 1
			local quote
			while i <= len do
				local c = source:sub(i, i)
				if quote then
					if c == quote then quote = nil end
				elseif c == '"' or c == "'" then
					quote = c
				elseif c == ">" then
					break
				end
				i = i + 1
			end
			local inner = source:sub(lt + 1, i - 1)
			local selfClosing = inner:sub(-1) == "/"
			if selfClosing then inner = inner:sub(1, -2) end
			local tag, rest = inner:match("^([%w_:]+)(.*)$")
			assert(tag, fileName .. ": bad tag near " .. source:sub(lt, lt + 40))
			local node = { tag = tag, attr = ParseAttributes(rest), children = {}, file = fileName }
			table.insert(top.children, node)
			if not selfClosing then
				table.insert(stack, node)
			end
			pos = i + 1
		end
	end
	if #stack ~= 1 then
		error(fileName .. ": unclosed <" .. stack[#stack].tag .. ">")
	end
	return root
end

function XML.ParseFile(path)
	local f = assert(io.open(path, "rb"))
	local source = f:read("*a")
	f:close()
	return XML.Parse(source, path)
end

return XML
