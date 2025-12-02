local M = {}

function M.should_show() -- only if no file or stdin given
    if vim.fn.argc() > 0 then return false end
    return true
end

function M.center(lines)
    local width = vim.api.nvim_win_get_width(0)
    local out = {}
    for _, line in ipairs(lines) do
        local pad = math.max(0, math.floor((width - #line) / 2))
        table.insert(out, string.rep(" ", pad) .. line)
    end
    return out
end

function M.shorten(str, n)
    if #str <= n then
        return str
    end
    return "..." .. str:sub(-n+3, -1)
end

function M.get_recent_files(n_recent)
    local files = vim.v.oldfiles or {}
    local out = {}
    for _, file in ipairs(files) do
        if vim.uv.fs_stat(file) then
            table.insert(out, file)
            if #out >= n_recent then
                return out
            end
        end
    end
    return out
end

return M
