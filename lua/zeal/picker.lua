local docsets = require("zeal.docsets")
local browser = require("zeal.browser")
local M = {}

function M.previewer_path()
	local root_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h:h')
	return vim.fs.joinpath(root_dir, "bin", "previewer.sh")
end

---@param docset table
---@param cfg table
---@param query string?
function M.pick_entry(docset, cfg, query)
	local entries = docsets.entries(docset)
	if #entries == 0 then
		vim.notify("zeal.nvim: no entries found in " .. docset.name, vim.log.levels.WARN)
		return
	end

	if cfg.picker.type == "fzf-lua" then
		local fzf_lua = require("fzf-lua")
		local items = vim.tbl_map(function(e)
			return string.format("%s\t%s", e.path, e.display)
		end, entries)
		fzf_lua.fzf_exec(items, {
			prompt = "Zeal [" .. docset.name .. "] > ",
			query = query,
			fzf_opts = {
				['--delimiter'] = "\t",
				['--with-nth'] = "2..",
				['--accept-nth'] = "{n}",
				['--preview'] = M.previewer_path() .. " {1}",
			},
			actions = {
				['default'] = function(selected)
					local choice = entries[tonumber(selected[1]) + 1]
					browser.open(choice, cfg)
				end,
			},
		})
		return
	end

	if cfg.picker.type == "default" then
		-- TODO: filter by query
		vim.ui.select(entries, {
			prompt = "Zeal [" .. docset.name .. "]:",
			format_item = function(e)
				return e.display
			end,
		}, function(choice)
			if choice then
				browser.open(choice, cfg)
			end
		end)
		return
	end

	local picker_cfg = cfg.picker.snacks
	local snacks = require("snacks")
	local items = {}

	for _, e in ipairs(entries) do
		table.insert(items, { text = e.display, path = e.path })
	end

	snacks.picker({
		items = items,
		pattern = query, -- XXX: untested
		format = function(e)
			return {
				{ e.text, "SnacksPickerFile" },
			}
		end,
		layout = picker_cfg.layout,
		title = " " .. docset.name .. " Entries",
		confirm = function(picker, choice)
			picker:close()
			browser.open(choice, cfg)
		end,
		preview = "none",
	})
end

---@param docset_names table list of docset name strings
---@param ft string
---@param cfg table
---@param query string?
function M.pick_entry_for_ft(docset_names, ft, cfg, query)
	local entries = docsets.entries_for_ft(docset_names, cfg)
	if #entries == 0 then
		vim.notify("zeal.nvim: no entries found for filetype " .. ft, vim.log.levels.WARN)
		return
	end

	if cfg.picker.type == "fzf-lua" then
		local fzf_lua = require("fzf-lua")
		local items = vim.tbl_map(function(e)
			return string.format("%s\t%s", e.path, e.display)
		end, entries)
		fzf_lua.fzf_exec(items, {
			prompt = "Zeal [" .. ft .. "] > ",
			query = query,
			fzf_opts = {
				['--delimiter'] = "\t",
				['--with-nth'] = "2..",
				['--accept-nth'] = "{n}",
				['--preview'] = M.previewer_path() .. " {1}",
			},
			actions = {
				['default'] = function(selected)
					local choice = entries[tonumber(selected[1]) + 1]
					browser.open(choice, cfg)
				end,
			},
		})
		return
	end

	if cfg.picker.type == "default" then
		-- TODO: filter by query
		vim.ui.select(entries, {
			prompt = "Zeal [" .. ft .. "]:",
			format_item = function(e)
				return e.display
			end,
		}, function(choice)
			if choice then
				browser.open(choice, cfg)
			end
		end)
		return
	end

	local picker_cfg = cfg.picker.snacks
	local snacks = require("snacks")
	local items = {}

	for _, e in ipairs(entries) do
		table.insert(items, { text = e.display, path = e.path })
	end

	snacks.picker({
		items = items,
		pattern = query, -- XXX: untested
		format = function(e)
			return {
				{ e.text, "SnacksPickerFile" },
			}
		end,
		layout = picker_cfg.layout,
		title = "  Zeal [" .. ft .. "]",
		confirm = function(picker, choice)
			picker:close()
			browser.open(choice, cfg)
		end,
		preview = "none",
	})
end

---@param cfg table
function M.pick_docset(cfg)
	local all = docsets.list(cfg)

	if #all == 0 then
		return
	end

	if #all == 1 then
		M.pick_entry(all[1], cfg)
		return
	end

	if cfg.picker.type == "fzf-lua" then
		local fzf_lua = require("fzf-lua")
		local items = vim.tbl_map(function(d) return d.name end, all)
		fzf_lua.fzf_exec(items, {
			prompt = "Zeal docsets> ",
			fzf_opts = {
				['--accept-nth'] = "{n}",
			},
			actions = {
				['default'] = function(selected)
					local choice = all[tonumber(selected[1]) + 1]
					M.pick_entry(choice, cfg)
				end,
			},
		})
		return
	end

	if cfg.picker.type == "default" then
		vim.ui.select(all, {
			prompt = "Zeal Docsets:",
			format_item = function(d)
				return d.name
			end,
		}, function(choice)
			if choice then
				M.pick_entry(choice, cfg)
			end
		end)
		return
	end

	local picker_cfg = cfg.picker.snacks
	local snacks = require("snacks")
	local items = {}

	for _, d in ipairs(all) do
		table.insert(items, { text = d.name, name = d.name, path = d.path, file = d.path })
	end

	snacks.picker({
		items = items,
		format = function(d)
			return {
				{ d.text, "SnacksPickerFile" },
			}
		end,
		layout = picker_cfg.layout,
		title = "  Zeal Docsets",
		confirm = function(picker, choice)
			picker:close()
			M.pick_entry(choice, cfg)
		end,
		preview = "none",
	})
end

---@param languages table[]
---@param cfg table
---@param callback function
function M.pick_download(languages, cfg, callback)
	if cfg.picker.type == "fzf-lua" then
		local fzf_lua = require("fzf-lua")
		local items = vim.tbl_map(function(l) return l.name end, languages)
		fzf_lua.fzf_exec(items, {
			prompt = "Zeal Docsets > ",
			fzf_opts = {
				['--accept-nth'] = "{n}",
			},
			actions = {
				['default'] = function(selected)
					local choice = languages[tonumber(selected[1]) + 1]
					callback(cfg, choice.name)
				end,
			},
		})
		return
	end

	if cfg.picker.type == "default" then
		vim.ui.select(languages, {
			prompt = "Zeal Docsets:",
			format_item = function(e)
				return e.name
			end,
		}, function(choice)
			if choice then
				callback(cfg, choice.name)
			end
		end)
		return
	end

	local picker_cfg = cfg.picker.snacks
	local snacks = require("snacks")
	local items = {}

	for _, e in ipairs(languages) do
		table.insert(items, { text = e.name, name = e.name })
	end

	snacks.picker({
		items = items,
		format = function(e)
			return {
				{ e.text, "SnacksPickerFile" },
			}
		end,
		layout = picker_cfg.layout,
		title = "  Zeal Docsets",
		confirm = function(picker, choice)
			picker:close()
			if choice then
				callback(cfg, choice.name)
			end
		end,
		preview = "none",
	})
end

return M
