module.exports = (utils, state, constants) ->
	render_started = false
	jf = require('jsfunky')
	newmsg = () ->
		msg = jf.clone(state.request_template)
		msg.login = state.request_template.login
		msg.password = state.request_template.password
		msg.cmd = 'CMD_ping'
		msg
	create_event = ({id: id, time_from: time_from, time_to: time_to, room_id: room_id, status: status, band_id: band_id}) ->
		m_from = moment(time_from * 1000)
		m_to = moment(time_to * 1000)
		percentfill = Math.abs(time_to - time_from) / 10800
		percentfill = if (percentfill > 1) then 1 else percentfill
		rooms = jf.get_in(state, ["response_state","rooms"])
		this_room = if (state.dicts.rooms_full and state.dicts.rooms_full[room_id.toString()]) then state.dicts.rooms_full[room_id.toString()] else null
		bands = jf.get_in(state, ["response_state","bands"])
		this_band = if (state.dicts.bands_full and state.dicts.bands_full[band_id.toString()]) then state.dicts.bands_full[band_id.toString()] else null
		{
			id: id,
			title: m_from.format('HH:mm')+" - "+m_to.format('HH:mm')+(if this_band then (" "+this_band.name) else ""),
			start: m_from.format('YYYY-MM-DD'),
			end: m_to.format('YYYY-MM-DD'),
			percentfill: percentfill,
			room_id: room_id,
			status: status,
			color: if not(this_room) then state.colors.sesions[status] else (if (status == "SS_awaiting_first") then this_room.color else net.brehaut.Color(this_room.color).setAlpha(0.3).toString())
		}
	long2date = (long) ->
		moment(1000 * parseInt(long.toString())).format('YYYY-MM-DD HH:mm:ss')
	# this shit is one way to refresh events on calendar ...
	utils.rerender_events_coroutine_process = (prevstate) ->
		# rm html elements and create new state ...
		newstate = jf.reduce(state, {}, (k,v,acc) -> (if (k in ["workday","datepair","calendar","datepairval","new_session","last_click"]) then acc else jf.put_in(acc, [k], jf.clone(v))))
		newstate.state_calendar_flag = not(state.calendar)
		if not(jf.equal(prevstate, newstate))
			#
			# RERENDER JQ TABLES
			#
			savedFilters = $('table').find('.tablesorter-filter').map(() -> @.value || '').get()
			savedFocus = $('table').find('.tablesorter-filter').map(() -> $(@).is(":focus")).get()
			$(".table-special-sorted").trigger('updateAll').get()
			$(".table-special-sorted")
				.find('.tablesorter-filter')
				.each((i, el) ->
					$(el).val(savedFilters[i]).trigger("change")
					if savedFocus[i] then $(el).focus())
				.get()
			#
			# RERENDER JQ TABLES
			#
			state.rnd = Math.random().toString()
			newstate.rnd = state.rnd
			if state.calendar
				scroll = document.getElementsByTagName("body")[0].scrollTop
				$(state.calendar).fullCalendar( 'removeEventSources' )
				$(state.calendar).fullCalendar( 'removeEvents' )
				active_statuses = jf.reduce(state.sessions_statuses, {}, ((s, acc) -> acc[s] = true ; acc))
				lst = state.events.filter((el) ->
					event_status_pred = active_statuses[el.status]
					room_pred = ((el.room_id.toString() == state.ids.room.toString()) or ((state.ids.room == false) and (state.ids.location == false)))
					location_pred = ((state.ids.room == false) and ((state.rooms_of_locations[el.room_id.toString()] == state.ids.location.toString()) or (state.ids.location == false)))
					((room_pred or location_pred) and event_status_pred))
				$(state.calendar).fullCalendar( 'addEventSource', lst)
				console.log("re-render "+lst.length.toString()+" events ... new state is")
				console.log(state)
				document.getElementsByTagName("body")[0].scrollTop = scroll
			newstate
		else
			prevstate
	utils.rerender_events_coroutine = (this_state) ->
		try
			this_state = if state.is_focused then utils.rerender_events_coroutine_process(this_state) else this_state
			setTimeout((() -> utils.rerender_events_coroutine(this_state)), 500)
		catch error
			console.log("RENDER EVENTS ERROR !!! ", error)
			setTimeout((() -> utils.rerender_events_coroutine(this_state)), 500)
	port = ":7772"
	#port = if location.port then ":"+location.port else ""
	bullet = $.bullet((if window.location.protocol == "https:" then "wss://" else "ws://") + location.hostname + port + location.pathname + "bullet")
	utils.bullet = bullet
	utils.newmsg = newmsg
	utils.to_server = (data) ->
		console.log(data)
		bullet.send( utils.encode_proto(data) )
	utils.bullet.onopen = () ->
		if ((state.request_template.login != '') and (state.request_template.password != ''))
			utils.CMD_get_state()
		else
			utils.bullet.onheartbeat()
		utils.notice("соединение с сервером установлено")
	utils.bullet.ondisconnect = () -> utils.error("соединение с сервером потеряно")
	utils.bullet.onclose = () -> utils.warn("соединение с сервером закрыто")
	utils.bullet.onheartbeat = () -> utils.to_server(newmsg())
	utils.CMD_get_state = () ->
		msg = newmsg()
		msg.cmd = 'CMD_get_state'
		utils.to_server(msg)
	utils.bullet.onmessage = (data) ->
		data = utils.decode_proto(data)
		console.log(data)
		switch data.status
			when "RS_ok_void" then "ok"
			when "RS_error" then utils.error(data.message)
			when "RS_warn"
				if (not(data.destination_location_id) or not(state.ids.location))
					constants.sounds.message.play()
					utils.warn(data.message, 30000)
				else
					if data.destination_location_id.some((el) -> el.compare(state.ids.location) == 0)
						constants.sounds.message.play()
						utils.warn(data.message, 30000)
			when "RS_notice"
				# prevent callback on hiding popups side-effect
				state.callbacks.close_popup = false
				# hide popups side-effect
				$('#calendarday').modal('hide')
				$('#group_popup').modal('hide')
				$('#week_template_popup').modal('hide')
				$('#transactions_popup').modal('hide')
				utils.notice(data.message)
			when "RS_info"
				utils.notice(data.message)
			when "RS_refresh" then (if state.response_state then utils.CMD_get_state())
			when "RS_ok_state"
				store.set("login", state.request_template.login)
				store.set("password", state.request_template.password)
				["locations", "instruments", "bands", "admins", "rooms"].forEach((k) ->
					state.dicts[(k+"_full")] = jf.reduce(data.state[k], {}, (el, acc) -> jf.put_in(acc, [el.id.toString()], el)))
				state.request_template.subject.hash = data.state.hash
				state.response_state = data.state
				if (data.state.sessions) then (state.events = data.state.sessions.map(create_event))
				state.dicts.locations = jf.reduce(data.state.locations, {}, ({id: id, name: name}, acc) -> jf.put_in(acc, [id.toString()], name.toString()))
				state.dicts.instruments = jf.reduce(data.state.instruments, {}, ({id: id, name: name}, acc) -> jf.put_in(acc, [id.toString()], name.toString()))
				state.dicts.bands = jf.reduce(data.state.bands, {}, (band, acc) -> jf.put_in(acc, [band.id.toString()], band))
				state.dicts.admins = jf.reduce(data.state.admins, {}, ({id: id, name: name}, acc) -> jf.put_in(acc, [id.toString()], name.toString()))
				state.dicts.rooms = jf.reduce(data.state.rooms, {}, ({id: id, name: name}, acc) -> jf.put_in(acc, [id.toString()], name.toString()))
				state.dicts.instruments_intervals = jf.reduce(data.state.instruments, {}, ({id: id}, acc) -> jf.put_in(acc, [id.toString()], utils.instrument_interval_dict(data.state.sessions.filter(({status: status}) -> status == "SS_awaiting_first"), id)))
				state.rooms_of_locations = jf.reduce(data.state.rooms, {}, ({id: id, location_id: lid}, acc) -> jf.put_in(acc, [id.toString()], lid.toString()))
				state.ids.admin = state.response_state.admins.filter((el) -> return (el.login == state.request_template.login) && (el.password == state.request_template.password))[0].id
			when "RS_statistics"
				state.statistics = data.statistics
		if state.callbacks.msg then state.callbacks.msg(state, data)
		if not(render_started)
			console.log("start render")
			utils.render_coroutine()
			utils.rerender_events_coroutine(null)
			if not(state.response_state) then $('[tabindex="' + 1  + '"]').focus()
			render_started = true
	utils
