window.methods.func = function (w, cmd, opts)
    w:set_mode("command")
    w:set_input(cmd, opts)
    w.ibar.input.select_region(w.ibar.input, 0, 10)
end

local key, buf, but = lousy.bind.key, lousy.bind.buf, lousy.bind.but
local cmd, any = lousy.bind.cmd, lousy.bind.any

add_binds("all", {
    key({"Control"}, "p", "Fuzzy-matching history and open tabs' navigator and launcher.",
        function (w) w:(m.count) end),
})

add_cmds({
    cmd("o[pen]", "Open one or more URLs.",
        function (w, a) w:navigate(w:search_open(a)) end),

    cmd("t[abopen]", "Open one or more URLs in a new tab.",
        function (w, a) w:new_tab(w:search_open(a)) end),
})


--------------------------------------------------------
-- Fuzzy-matching launcher for history and open tabs. --
-- © 2012 Vic Goldfeld <vic@longstorm.org>            --
-- Code borrowed from tabhistory by authors below.    --
-- © 2010 Fabian Streitel <karottenreibe@gmail.com>   --
-- © 2010 Mason Larobina  <mason.larobina@gmail.com>  --
--------------------------------------------------------

local util = require("lousy.util")
local join = util.table.join

-- View history items in an interactive menu.
new_mode("launcher", {
    leave = function (w)
        w.menu:hide()
    end,

    enter = function (w)
        local h = w.view.history
        local rows = {{"Title", "URI", title = true},}
        for i, hi in ipairs(h.items) do
            local title, uri = util.escape(hi.title), util.escape(hi.uri)
            local marker = (i == h.index and "* " or "  ")
            table.insert(rows, 2, { (marker..title), uri, index=i})
        end
        w.menu:build(rows)
        w:notify("Use j/k to move, w winopen, t tabopen.", false)
    end,
})

-- Add history menu binds.
local key = lousy.bind.key
add_binds("tabhistory", join({
    -- Open history item in new tab.
    key({}, "t", function (w)
        local row = w.menu:get()
        if row and row.index then
            local v = w.view
            local uri = v.history.items[row.index].uri
            w:new_tab(uri, false)
        end
    end),

    -- Open history item in new window.
    key({}, "w", function (w)
        local row = w.menu:get()
        w:set_mode()
        if row and row.index then
            local v = w.view
            local uri = v.history.items[row.index].uri
            window.new({uri})
        end
    end),

    -- Go to history item.
    key({}, "Return", function (w)
        local row = w.menu:get()
        w:set_mode()

        w.tabs:switch(index)

        if row and row.index then
            local v = w.view
            local offset = row.index - v.history.index
            if offset < 0 then
                v:go_back(-offset)
            elseif offset > 0 then
                v:go_forward(offset)
            end
        end
    end),

}, menu_binds))

-- Additional window methods.
window.methods.tab_history = function (w)
    if #(w.view.history.items) < 2 then
        w:notify("No history items to display")
    else
        w:set_mode("tabhistory")
    end
end

-- Add `:history` command to view all history items for the current tab in an interactive menu.
local cmd = lousy.bind.cmd
add_cmds({
    cmd("tabhistory", "list history for tab", window.methods.tab_history),
})

-- vim: et:sw=4:ts=8:sts=4:tw=80
