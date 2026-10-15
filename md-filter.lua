-- Clean up xml2rfc HTML before converting to Markdown.
-- Drops I-D boilerplate, the table of contents, and internal anchor
-- links, and unwraps the layout divs so the Markdown stays line-based
-- and easy to review.

local drop = {
  ["external-metadata"] = true,
  ["internal-metadata"] = true,
  ["status-of-memo"] = true,
  ["copyright"] = true,
  ["toc"] = true,
}

function Div(el)
  if drop[el.identifier] then
    return {}
  end
  return el.content
end

function Table(el)
  if el.classes:includes("ears") then
    return {}
  end
end

function Link(el)
  if (el.target or ""):sub(1, 1) == "#" then
    return el.content
  end
end
