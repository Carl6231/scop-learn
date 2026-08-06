local BASE = "https://carl6231.github.io/scop-learn/"
local SITE_NAME = "SCOP Learn"
local DESCRIPTION = "A source-grounded, bilingual curriculum for the SCOP R package."
local IMAGE = BASE .. "assets/social-card.png"

local function stringify(meta, key)
  if meta[key] == nil then
    return nil
  end
  return pandoc.utils.stringify(meta[key])
end

local function escape(value)
  return (value:gsub("&", "&amp;"):gsub("\"", "&quot;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function page_route()
  local output = quarto.doc.output_file
  local root = quarto.project.output_directory
  if output == nil or output == "" or root == nil or root == "" then
    return nil
  end

  local relative = pandoc.path.make_relative(output, root):gsub("\\", "/")
  if relative == "index.html" then
    return "", "en"
  end
  local zh_route = relative:match("^zh/(.*)$")
  if zh_route ~= nil then
    if zh_route == "index.html" then
      return "", "zh"
    end
    return zh_route, "zh"
  end
  return relative, "en"
end

local function translated_url(base, route, language)
  if route:match("/index%.html$") then
    route = route:gsub("/index%.html$", "/")
  end
  if route == "index.html" then
    route = ""
  end
  if language == "zh" then
    return base .. "zh/" .. route
  end
  return base .. route
end

function Meta(meta)
  local route, language = page_route()
  if route == nil then
    return meta
  end

  local base = BASE
  local site_name = SITE_NAME
  local description = stringify(meta, "description") or DESCRIPTION

  local english = translated_url(base, route, "en")
  local chinese = translated_url(base, route, "zh")
  local canonical = language == "zh" and chinese or english
  local title = stringify(meta, "pagetitle") or stringify(meta, "title") or site_name
  local locale = language == "zh" and "zh_CN" or "en_US"
  local alternate_locale = language == "zh" and "en_US" or "zh_CN"

  local tags = table.concat({
    '<meta name="description" content="' .. escape(description) .. '">',
    '<link rel="canonical" href="' .. escape(canonical) .. '">',
    '<link rel="alternate" hreflang="en" href="' .. escape(english) .. '">',
    '<link rel="alternate" hreflang="zh-Hans" href="' .. escape(chinese) .. '">',
    '<link rel="alternate" hreflang="x-default" href="' .. escape(english) .. '">',
    '<meta property="og:type" content="website">',
    '<meta property="og:title" content="' .. escape(title) .. '">',
    '<meta property="og:description" content="' .. escape(description) .. '">',
    '<meta property="og:url" content="' .. escape(canonical) .. '">',
    '<meta property="og:site_name" content="' .. escape(site_name) .. '">',
    '<meta property="og:image" content="' .. escape(IMAGE) .. '">',
    '<meta property="og:image:type" content="image/png">',
    '<meta property="og:image:width" content="1200">',
    '<meta property="og:image:height" content="630">',
    '<meta property="og:image:alt" content="SCOP Learn source-grounded bilingual curriculum">',
    '<meta property="og:locale" content="' .. locale .. '">',
    '<meta property="og:locale:alternate" content="' .. alternate_locale .. '">',
    '<meta name="twitter:card" content="summary_large_image">',
    '<meta name="twitter:image" content="' .. escape(IMAGE) .. '">',
    '<meta name="twitter:title" content="' .. escape(title) .. '">',
    '<meta name="twitter:description" content="' .. escape(description) .. '">'
  }, "\n")
  quarto.doc.include_text("in-header", tags)
  return meta
end
