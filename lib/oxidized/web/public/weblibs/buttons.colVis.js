

(function(factory){
	if (typeof define === 'function' && define.amd) {
		// AMD
		define(['datatables.net', 'datatables.net-buttons'], function (dt) {
			return factory(window, document, dt);
		});
	}
	else if (typeof exports === 'object') {
		if (typeof window === 'undefined') {
			module.exports = function (root) {
				if (! root) {
					// CommonJS environments without a window global must pass a
					// root. This will give an error otherwise
					root = window;
				}
				
				var DataTable = root.DataTable ?
					root.DataTable :
					require('datatables.net')(root);

				if (! root.DataTable.Buttons) {
					require('datatables.net-buttons')(root);
				}

				return factory(root, root.document, DataTable);
			};
		}
		else {
			var DataTable = window.DataTable ?
				window.DataTable :
				require('datatables.net');

			if (! window.DataTable.Buttons) {
				require('datatables.net-buttons');
			}

			module.exports = factory(window, window.document, DataTable);
		}
	}
	else {
		// Browser
		factory(window, document, window.DataTable);
	}
}(function(window, document, DataTable) {
'use strict';

// File intentionally empty


return DataTable;
}));
