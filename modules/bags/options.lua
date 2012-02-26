local E, L, P, G = unpack(select(2, ...)); --Import: Engine, Locales, ProfileDB, GlobalDB
local B = E:GetModule('Bags')

E.Options.args.bags = {
	type = 'group',
	name = L['Bags'],
	get = function(info) return E.db.bags[ info[#info] ] end,
	set = function(info, value) E.db.bags[ info[#info] ] = value end,
	disabled = function() return not E.global.general.bags end,
	args = {
		intro = {
			order = 1,
			type = 'description',
			name = L['BAGS_DESC'],
		},
		bagCols = {
			order = 2,
			type = 'range',
			name = L['Bag Columns'],
			desc = L['Number of columns (width) of bags. Set it to 0 to match the width of the chat panels.'],
			min = 0, max = 30, step = 1,
		},
		bankCols = {
			order = 3,
			type = 'range',
			name = L['Bank Columns'],
			desc = L['Number of columns (width) of the bank. Set it to 0 to match the width of the chat panels.'],
			min = 0, max = 30, step = 1,
		},
		sortOrientation = {
			order = 4,
			type = 'select',
			name = L['Sort Orientation'],
			desc = L['Direction the bag sorting will use to allocate the items.'],
			values = {
				['BOTTOM-TOP'] = L['From Bottom to Top'],
				['TOP-BOTTOM'] = L['From Top to Bottom'],
			},
		},
	},
}