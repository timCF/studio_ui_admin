proto2base64 = require('base64-arraybuffer')
jf = require("jsfunky")
module.exports =
	error: (mess) -> toastr.error(mess)
	warn: (mess) -> toastr.warning(mess)
	notice: (mess) -> toastr.success(mess)
	info: (mess) -> toastr.info(mess)
	view_get: (state, path) -> jf.get_in(state, path)
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
		if (ev? and ev.target? and ev.target.value?)
			subj = ev.target.value
			Imuta.update_in(state, ["ids","location"], (_) -> (if subj == "" then false else subj))
	set_room: (state, path, ev) ->
		utils = @
		if (ev? and ev.target? and ev.target.value?)
			subj = ev.target.value
			Imuta.update_in(state, path, (_) -> (if subj == "" then false else subj))
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
	multiple_select: (state, path, ev) ->
		if (ev? and ev.target?)
			jf.put_in(state, path, [].slice.call(ev.target.options).filter((el) -> el.selected).map((el) -> el.value))
	session_new_edit: (state) ->
		# change / close old session
		utils = @
		if state.datepairval.date.start and state.datepairval.date.end and state.datepairval.time.start and state.datepairval.time.end
			msg = utils.newmsg()
			{time_from: tf, time_to: tt} = utils.get_time_from_to(state)
			d1 = new Date()
			d2 = new Date()
			d1.setTime(tf)
			d2.setTime(tt)
			console.log(d1,d2)
			#
			#	TODO
			#
			if state.new_session.id
				state.new_session.admin_id_close = state.ids.admin
			else # new session
				state.new_session.admin_id_open = state.ids.admin
		else
			utils.error("не выбран временной интервал сессии")
	date2moment: (date) ->
		moment(date.getTime())
	get_time_from_to: (state) ->
		utils = @
		pd = "YYYY-MM-DD"
		pt = "HH:mm:ss"
		{
			time_from: (moment( (utils.date2moment(state.datepairval.date.start).format(pd)+utils.date2moment(state.datepairval.time.start).format(pt)) , pd+pt ).unix() * 1000),
			time_to: (moment( (utils.date2moment(state.datepairval.date.end).format(pd)+utils.date2moment(state.datepairval.time.end).format(pt)) , pd+pt ).unix() * 1000)
		}
	clonedate: (date) ->
		newdate = new Date()
		newdate.setTime(date.getTime())
		newdate
