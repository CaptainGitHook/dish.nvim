local M = {}


local conf = {
    banner=vim.fn.readfile(vim.api.nvim_get_runtime_file("data/ramen.sh", false)[1]),
    bannerpath="",
    path="", -- Not implemented yet
    projpaths={},
    N_RECENT=5
}


function M.setup(opts)
    local utils = require("dish.utils")
    conf = vim.tbl_deep_extend('force', conf, opts or {})

    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
            if not utils.should_show() then return end

            local opts = {
                number = vim.wo.number,
                relativenumber = vim.wo.relativenumber,
                cursorline = vim.wo.cursorline,
                cursorcolumn = vim.wo.cursorcolumn,
                wrap = vim.wo.wrap,
            }


            vim.cmd("enew")
            local buf = vim.api.nvim_get_current_buf()
            vim.api.nvim_create_autocmd("BufLeave", {
                callback = function()
                    -- Enable numbers and stuff for all normal windows
                    for k,v in pairs(opts) do
                        vim.wo[k] = v
                    end
                end,
            })

            -- Set buffer options *before* writing
            vim.bo[buf].buftype = "nofile"
            vim.bo[buf].bufhidden = "hide"
            vim.bo[buf].swapfile = false
            vim.bo[buf].modifiable = true
            vim.bo[buf].buflisted = false

            vim.wo.wrap = false
            vim.wo.number = false
            vim.wo.relativenumber = false

            -- Build content
            local ascii = ""
            if conf.bannerpath ~= "" then
                if vim.fn.filereadable(conf.bannerpath) then
                    ascii = vim.fn.readfile(conf.bannerpath)
                else
                    ascii = conf.bannerpath .. " could not be found."
                end
            elseif type(conf.banner) == "function" then
                ascii = conf.banner()
            else
                ascii = conf.banner
            end

            local lines
            if type(ascii) == "table" then
                lines = ascii
            else
                lines = vim.split(ascii, "\n", { plain = true })
            end
            local height = vim.api.nvim_win_get_height(0)
            for _=1, math.max(5, math.floor(0.5*(height*0.8-#lines))) do
                table.insert(lines,1,"") -- insert in front
                table.insert(lines,"") -- insert in back
            end

            -- Layout: first 80% picture, fifthlast line onwards: stuff
            for _=1, math.max(1, math.floor(height-3-#lines)) do
                table.insert(lines, "")
            end


            local highlight_lines = {}
            local r = ""
            local recent = utils.get_recent_files(conf.N_RECENT)
            local width  = vim.api.nvim_win_get_width(0)
            local length = (width-4)/#recent - 17
            if #recent > 0 then
                r = "  "
                for i, file in ipairs(recent) do
                    r = r .. string.format("      %d  %s      |", i, utils.shorten(file, length))
                    vim.keymap.set("n", tostring(i), function()
                        vim.cmd("e " .. vim.fn.fnameescape(file))
                    end, { buffer = buf })
                end
                r = r:sub(1, -2) .. "  "

                table.insert(lines, r)
                table.insert(highlight_lines, #lines)

            else
                table.insert(lines, "no recent files")
            end

            table.insert(lines, "")
            if conf.path ~= "" then -- For the future
            end

            r = "  " -- TODO: Highlighting
            local icons = {"q","w","e","r","t","z","u","i","o","p"}
            for i, file in ipairs(conf.projpaths) do
                r = r .. string.format("      %s  %s      |", icons[i], utils.shorten(file, length))
                vim.keymap.set("n", icons[i], function()
                    vim.cmd("e " .. vim.fn.fnameescape(file))
                    for k, v in pairs(opts) do
                        vim.wo[k] = v
                    end
                end, { buffer = buf })

            end
            r = r:sub(1, -2) .. "  "

            table.insert(lines, r)
            table.insert(highlight_lines, #lines)

            lines = utils.center(lines)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

            -- highlight clickables
            vim.api.nvim_set_hl(0, "Num", { fg = "#FFA500", bold = true })
            for _, linenum in ipairs(highlight_lines) do
                local line = lines[linenum]
                for number in line:gmatch("%d+") do
                    -- find the position of that number in the line
                    local start = line:find(number, 1, true)
                    if start then
                        local finish = start + #number
                        vim.api.nvim_buf_add_highlight(
                            buf,
                            0,
                            "Num",
                            linenum-1,           -- line index (0-based)
                            start - 1,       -- start column
                            finish - 1       -- end column
                        )
                    end
                end
            end

            -- Lock the buffer
            vim.bo[buf].modifiable = false
            vim.bo[buf].readonly = true
        end,
    })
end

return M
