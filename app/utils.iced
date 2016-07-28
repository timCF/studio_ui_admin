proto2base64 = require('base64-arraybuffer')
jf = require("jsfunky")
module.exports =
	error: (mess) -> toastr.error(mess)
	warn: (mess) -> toastr.warning(mess)
	notice: (mess) -> toastr.success(mess)
	info: (mess) -> toastr.info(mess)
	view_get: (state, path) -> jf.get_in(state, path)
	view_put: (state, path, data) -> Imuta.update_in(state, path, (_) -> data)
	view_put_render: (state, path, data) ->
		utils = @
		Imuta.update_in(state, path, (_) -> data)
		utils.render()
	view_set: (state, path, ev) ->
		if (ev? and ev.target? and ev.target.value?)
			subj = ev.target.value
			Imuta.update_in(state, path, (_) -> subj)
	set_location: (state, ev) ->
		utils = @
		if (ev? and ev.target? and ev.target.value?)
			subj = ev.target.value
			state.ids.location = false
			state.ids.room = false
			await utils.render(defer dummy)
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
		if not(state.datepairval.date.start and state.datepairval.date.end and state.datepairval.time.start and state.datepairval.time.end)
			utils.error("не выбран временной интервал сессии")
		else if not(state.new_session.band_id)
			utils.error("не выбрана группа")
		else
			msg = utils.newmsg()
			session = utils.merge(state.new_session, utils.get_time_from_to(state))
			wd = (date = new Date() ; date.setTime(session.time_from) ; date).getDay()
			if (wd == 0) then (session.week_day = "WD_7") else (session.week_day = "WD_"+wd)
			if state.new_session.id
				msg.cmd = 'CMD_edit_session'
				session.admin_id_close = state.ids.admin
			else # new session
				msg.cmd = 'CMD_new_session'
				session.admin_id_open = state.ids.admin
			msg.subject.sessions = [session]
			utils.to_server(msg)
	band_new_edit: (state) ->
		utils = @
		contacts = jf.reduce(Object.keys(state.verbose.contacts), state.new_band.contacts, (k, acc) -> acc[k] = $('#contacts-list-'+k).tagsinput('items') ; acc )
		state.new_band.contacts = contacts
		state.new_band.name = $.trim(state.new_band.name)
		state.new_band.person = $.trim(state.new_band.person)
		if (contacts.phones.length == 0)
			utils.error("должен быть хотя бы один номер телефона")
		else if (state.new_band.name == "")
			utils.error("нужно ввести имя группы")
		else if (state.new_band.person == "")
			utils.error("нужно ввести контактное лицо")
		else
			state.new_band.contacts = contacts
			msg = utils.newmsg()
			msg.cmd = 'CMD_band_new_edit'
			msg.subject.bands = [state.new_band]
			utils.to_server(msg)
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
	edit_band: (state, el) ->
		utils = @
		this_band = utils.clone_proto(el, "Band")
		state.new_band = false
		await utils.render(defer dummy)
		state.new_band = this_band
		await utils.render(defer dummy)
		$('#group_popup').modal()
	new_band: (state) ->
		utils = @
		band = new utils.proto.Band
		band.id = null
		band.name = ""
		band.person = ""
		contacts = new utils.proto.Contacts
		contacts.phones = []
		contacts.mails = []
		contacts.social = []
		contacts.other = []
		band.contacts = contacts
		band.kind = "BK_base"
		band.description = ""
		band.balance = 0
		band.admin_id = state.ids.admin
		band.can_order = false
		band.enabled = true
		band
	new_week_template: (state) ->
		utils = @
		st = new utils.proto.SessionTemplate
		st.id = null
		st.min_from = 540
		st.min_to = 720
		st.week_day = "WD_1"
		st.room_id = state.ids.room
		st.instruments_ids = []
		st.band_id = null
		st.description = ""
		st.admin_id = state.ids.admin
		st.enabled = true
		st.stamp = null
		st
	check_phone: (str) -> not(not(str.match(/\+\d\d\d\d\d\d\d\d\d\d\d/)))
	merge: (target, obj) -> jf.reduce(obj, target, (k,v,acc) -> acc[k] = v ; acc)
	timeout: (ttl, func) -> setTimeout(func, ttl)
	new_group_from_session: (state) ->
		utils = @
		if not(state.datepairval.date.start and state.datepairval.date.end and state.datepairval.time.start and state.datepairval.time.end)
			utils.error("не выбран временной интервал сессии")
		else
			this_session = state.new_session
			datepairval = {date: {}, time: {}}
			# clone datepairval
			["start","end"].forEach((key) ->
				datepairval.date[key] = utils.clonedate(state.datepairval.date[key])
				datepairval.time[key] = utils.clonedate(state.datepairval.time[key]))
			$('#calendarday').modal('hide')
			await utils.render(defer dummy)
			state.current_page = "edit_groups"
			await utils.render(defer dummy)
			utils.timeout(500, () ->
				back_to_calendar = () ->
					await utils.render(defer dummy)
					state.current_page = "calendar_main"
					await utils.render(defer dummy)
					state.new_session = this_session
					await utils.render(defer dummy)
					utils.timeout(500, () ->
						["start","end"].forEach((key) ->
							$('#datepair .date.'+key).datepicker('setDate', datepairval.date[key])
							$('#datepair .time.'+key).timepicker('setTime', datepairval.time[key]))
						await utils.render(defer dummy)
						$('#calendarday').modal())
				state.callbacks.close_popup = (state) ->
					console.log("callbacks.close_popup")
					state.callbacks.close_popup = false
					state.callbacks.msg = false
					back_to_calendar()
				state.callbacks.msg = (state, _) ->
					console.log("callbacks.msg")
					if state.new_band
						[band] = state.response_state.bands.filter((el) -> (el.name == state.new_band.name) and (el.person == state.new_band.person))
						if band
							state.new_session.band_id = band.id
							state.callbacks.close_popup = false
							state.callbacks.msg = false
							back_to_calendar()
				utils.edit_band(state, utils.new_band(state)))
	week_template_edit: (state, el) ->
		utils = @
		if not(el.room_id)
			utils.error("не выбрана комната")
		else
			this_band_id = if el.band_id then el.band_id.toString() else null
			el.band_id = if el.band_id then el.band_id else 999 # only for clone
			this_data = utils.clone_proto(el, "SessionTemplate")
			this_data.band_id = this_band_id
			this_data.room_id = this_data.room_id.toString()
			state.new_week_template = false
			await utils.render(defer dummy)
			state.new_week_template = this_data
			await utils.render(defer dummy)
			utils.timeout(500, () ->
				ds = utils.minutes2moment(this_data.min_from).toDate()
				de = utils.minutes2moment(this_data.min_to).toDate()
				$('#datepair .date.start').datepicker('setDate', ds)
				$('#datepair .date.end').datepicker('setDate', de)
				$('#datepair .time.start').timepicker('setTime', ds)
				$('#datepair .time.end').timepicker('setTime', de)
				await utils.render(defer dummy)
				utils.new_datepairval(state)
				await utils.render(defer dummy)
				$('#week_template_popup').modal())
	week_template_new_edit: (state) ->
		utils = @
		state.new_week_template.min_from = utils.date2minutes( state.datepairval.time.start )
		state.new_week_template.min_to = utils.date2minutes( state.datepairval.time.end )
		if not(state.new_week_template.band_id)
			utils.error("необходимо выбрать группу")
		else
			msg = utils.newmsg()
			msg.cmd = 'CMD_week_template_new_edit'
			msg.subject.sessions_template = [state.new_week_template]
			utils.to_server(msg)
	week_template_disable: (state) ->
			utils = @
			msg = utils.newmsg()
			msg.cmd = 'CMD_week_template_disable'
			msg.subject.sessions_template = [state.new_week_template]
			utils.to_server(msg)
	minutes2moment: (data) ->
		data = parseInt(data)
		moment({minutes: data % 60, hours: Math.floor(data / 60)})
	date2minutes: (date) ->
		date.getMinutes() + (60 * date.getHours())
	new_datepairval: (state) ->
		utils = @
		console.log("new datepairval")
		state.datepairval.date.start = $('#datepair .date.start').datepicker('getDate')
		state.datepairval.date.end = $('#datepair .date.end').datepicker('getDate')
		state.datepairval.time.start = $('#datepair .time.start').timepicker('getTime')
		state.datepairval.time.end = $('#datepair .time.end').timepicker('getTime')
		if (state.datepairval.date.start and state.datepairval.time.start and state.datepairval.time.end)
			date = utils.clonedate(state.datepairval.date.start)
			switch (state.datepairval.time.start <= state.datepairval.time.end) and not((state.datepairval.time.end.getMinutes() == 0) and (state.datepairval.time.end.getHours() == 0))
				when true then state.datepairval.date.end = date
				when false
					date.setDate(date.getDate() + 1)
					state.datepairval.date.end = date
			$('#datepair .date.end').datepicker('setDate', date)
