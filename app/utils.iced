proto2base64 = require('base64-arraybuffer')
module.exports =
	error: (mess) -> $.growl.error({title: '', message: mess , duration: 20000})
	warn: (mess) -> $.growl.warning({title: '', message: mess , duration: 20000})
	notice: (mess) -> $.growl.notice({title: '', message: mess , duration: 20000})
	info: (mess) -> $.growl({title: '', message: mess , duration: 20000})
	view_put: (state, path, data) -> Imuta.update_in(state, path, (_) -> data)
	view_set: (state, path, ev) ->
		if (ev? and ev.target? and ev.target.value?)
			subj = ev.target.value
			Imuta.update_in(state, path, (_) -> subj)
	set_location: (state, ev) ->
		utils = @
		state.ids.location = false
		state.ids.room = false
		utils.render()
		utils.view_set(state, ["ids","location"], ev)
	set_room: (state, path, ev) ->
		utils = @
		utils.view_set(state, path, ev)
	view_swap: (state, path) ->
		Imuta.update_in(state, path, (bool) -> not(bool))
	view_files: (state, path, ev) ->
		if (ev? and ev.target? and ev.target.files? and (ev.target.files.length > 0))
			Imuta.update_in(state, path, (_) -> [].map.call(ev.target.files, (el) -> el))
			console.log(Imuta.access_in(state, path))
	maybe_from_store: (key, defval) ->
		value = store.get(key)
		if value then value else defval
	logout: (state) ->
		store.remove("login")
		store.remove("password")
		state.response_state = false
		if state.request_template
			state.request_template.login = ''
			state.request_template.password = ''
		location.reload()
	new_session: (state) ->
		utils = @
		subj = new utils.proto.Session
		subj.time_from = null
		subj.time_to = null
		subj.week_day = null
		subj.room_id = state.ids.room
		subj.instruments_ids = []
		subj.band_id = null
		subj.callback = false
		subj.status = 'SS_awaiting_first'
		subj.amount = 0
		subj.description = ''
		subj.ordered_by = 'SO_admin'
		subj.admin_id_open = state.ids.admin
		subj.admin_id_close = 0
		subj.transaction_id = 0
		subj
	clone_proto: (data, datatype) ->
		utils = @
		utils.stringifyEnums(utils.proto[datatype].decode(utils.proto[datatype].encode(data)))
