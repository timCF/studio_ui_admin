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
		utils.rerender_events()
	set_room: (state, path, ev) ->
		utils = @
		utils.view_set(state, path, ev)
		utils.rerender_events()
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
