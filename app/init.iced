document.addEventListener "DOMContentLoaded", (e) ->
	jf = require("jsfunky")
	timepicker_opts = {
		minTime: "9:00",
		maxTime: "24:00",
		timeFormat: 'H:i',
		disableTextInput: true,
		disableTouchKeyboard: true,
		show2400: true,
		step: 60
	}
	datepicker_opts = {
		format: 'dd/mm/yyyy',
		autoclose: true,
		daysOfWeekHighlighted: '06',
		disableTouchKeyboard: true,
		todayBtn: true,
		todayHighlight: true,
		weekStart: 1,
	}
	calendar_opts = {
		height: "auto",
		lang: 'ru',
		firstDay: 1,
		monthNames: [
			"Январь",
			"Февраль",
			"Март",
			"Апрель",
			"Май",
			"Июнь",
			"Июль",
			"Август",
			"Сентябрь",
			"Октябрь",
			"Ноябрь",
			"Декабрь",
		],
		dayNames: [
			"Воскресенье",
			"Понедельник",
			"Вторник",
			"Среда",
			"Четверг",
			"Пятница",
			"Суббота",
		],
		buttonText: {
			today: 'сегодня',
			month: 'месяц',
			week: 'неделя',
			day: 'день'
		},
		columnFormat: 'dddd',
		dayClick: ((date, _, __) ->
			if state.ids.room
				state.datepairval.time.start = ''
				state.datepairval.time.end = ''
				state.new_session = utils.new_session(state)
				state.workday = false
				await utils.render(defer dummy) # reset popup to reset content
				state.workday = date
				await utils.render(defer dummy) # rerender new popup
				utils.timeout(500, () ->
					$('#datepair .time.start').timepicker('setTime', '')
					$('#datepair .time.end').timepicker('setTime', '')
					$('#datepair .date.start').datepicker('setDate', date.toDate())
					await utils.render(defer dummy)
					$('#calendarday').modal())
			else
				utils.error("не выбрана комната")),
		eventAfterRender: ((data, element, _) -> $(element).css('width', ($(element).width() * data.percentfill) + 'px'))
		eventClick: ({id: id}, _, __) ->
			state.new_session = utils.clone_proto(state.response_state.sessions.filter(({id: this_id}) -> this_id.compare(id) == 0)[0], "Session")
			state.workday = false
			await utils.render(defer dummy) # reset popup to reset content
			state.workday = moment(state.new_session.time_from.toString() * 1000)
			await utils.render(defer dummy) # rerender new popup
			ds = moment(state.new_session.time_from.toString() * 1000).toDate()
			de = moment(state.new_session.time_to.toString() * 1000).toDate()
			utils.timeout(500, () ->
				$('#datepair .date.start').datepicker('setDate', ds)
				$('#datepair .date.end').datepicker('setDate', de)
				$('#datepair .time.start').timepicker('setTime', ds)
				$('#datepair .time.end').timepicker('setTime', de)
				await utils.render(defer dummy)
				utils.new_datepairval(state)
				$('#calendarday').modal())
	}
	# state for main function, mutable
	constants = {
		sounds: {
			event: (new Audio('mp3/event.mp3')),
			message: (new Audio('mp3/message.mp3')),
			unknown: (new Audio('mp3/unknown.mp3')),
		}
	}
	state = {
		is_focused: true,
		last_click: moment(),
		sessions_statuses: [
			"SS_awaiting_first",
			"SS_closed_ok",
			"SS_canceled_hard",
		],
		callbacks: {
			msg: false,
			close_popup: false,
		},
		# this is custom callback, function (message, state)
		# called on new message from server for dynamic smart popups
		dicts: {},
		statistics: false,
		mutex: false,
		rnd: Math.random().toString(),
		colors: {
			sesions: {
				SS_awaiting_last:"#c1f0f0",
				SS_awaiting_first:"#00ccff",
				SS_closed_auto:"#c2d6d6",
				SS_closed_ok:"#00cc99",
				SS_canceled_soft:"#ffe6e6",
				SS_canceled_hard:"#ff1a1a",
			}
		}
		dimensions: {
			width: 0,
			height: 0
		},
		rooms_of_locations: {}, # just dict room_id => location_id
		pages_list: [
			{key: "calendar_main", icon: "fa-calendar", tt: "календарь", style: "color4"},
			{key: "edit_groups", icon: "fa-users", tt: "группы", style: "color5"},
			{key: "week_template", icon: "fa-database", tt: "постоянка", style: "color6"},
			{key: "transactions", icon: "fa-usd", tt: "транзакции", style: "color8"},
			{key: "statistics", icon: "fa-line-chart", tt: "статистика", style: "color7"},
		],
		groups_header: [
			{key: "name", transl: "группа"},
			{key: "person", transl: "лицо"},
			{key: "contacts", transl: "контакты"},
			{key: "kind", transl: "тип"},
			{key: "description", transl: "комментарий"},
			{key: "balance", transl: "баланс"},
			{key: "can_order", transl: "разрешено заказывать"},
		],
		current_page: "calendar_main",
		events: [], # calendar events to render
		opts: {},
		data: {},
		# current data
		ids: {
			location: false,
			room: false,
			admin: false
		},
		request_template: false,
		response_state: false,
		workday: moment(),
		datepair: false,
		calendar: false,
		datepairval: {
			date: {start: '', end: ''},
			time: {start: '', end: ''}
		},
		new_session: null,
		new_band: null,
		new_week_template: null,
		new_transaction: null,
		verbose: require("verbose")
	}
	render = (cb) ->
		state.dimensions.height = window.innerHeight
		state.dimensions.width = window.innerWidth
		render_datepair()
		render_calendar()
		render_tooltips()
		render_jqcb()
		render_tables()
		render_taglists()
		await react.render(widget(fullstate), document.getElementById("main_frame"), defer dummy)
		if jf.is_function(cb,1) then cb(state)
		dummy
	render_coroutine = () ->
		try
			if state.is_focused
				["location","room"].forEach((k) ->
					this_data = if state.ids[k] then state.ids[k].toString() else false
					if (store.get(k+"_id") != this_data) then store.set(k+"_id", this_data))
				render()
				if (moment().diff(state.last_click, 'seconds') > 60) then window.onblur()
			#
			# need this shit to prevent memory leaks
			#
			if (moment().diff(state.last_click, 'minutes') > 10) then window.location.reload(true)
			setTimeout(render_coroutine, 500)
		catch error
			console.log("RENDER ERROR !!! ", error)
			window.location.reload(true)
	# some compile-time defined utils, frozen
	utils = Object.freeze(tmp = require("bullet")(require("proto")(require("utils")), state, constants) ; tmp.render = render ; tmp.render_coroutine = render_coroutine ; tmp)
	state.ids.location = utils.maybe_from_store("location_id", false)
	state.ids.room = utils.maybe_from_store("room_id", false)
	# full state structure, frozen
	fullstate = Object.freeze({state: state, utils: utils})
	react = require("react-dom")
	widget = require("widget")
	render_datepair = () ->
		datepair = document.getElementById('datepair')
		if not(datepair) then (state.datepair = false)
		if not(state.datepair) and datepair
			$('#datepair .time').timepicker(timepicker_opts)
			$('#datepair .date').datepicker(datepicker_opts)
			state.datepair = new Datepair(datepair, {defaultTimeDelta: 10800000, defaultDateDelta: null})
			$('#datepair').on('rangeSelected', () -> utils.new_datepairval(state))
			$('#datepair').on('rangeError', () -> utils.new_datepairval(state))
			$('#datepair').on('rangeIncomplete', () -> utils.new_datepairval(state))
			console.log("render datepair")
	render_calendar = () ->
		calendar = document.getElementById('calendar')
		if state.calendar and not(calendar)
			$(state.calendar).fullCalendar('destroy')
			state.calendar.remove()
			delete state.calendar
			state.calendar = false
		if not(state.calendar) and calendar
			state.calendar = $(calendar).fullCalendar(calendar_opts)
			console.log("render calendar")
	render_tooltips = () ->
		$('[data-toggle="tooltip"]').tooltip()
		$('.selectpicker').selectpicker({noneSelectedText: "ничего не выбрано"})
		out = $(".tooltip").attr('id')
		if out and ($("[aria-describedby='"+out+"']").length == 0)
			$( document.getElementById(out) ).remove()
			console.log("destroy tooltip "+out)
	render_jqcb = () ->
		$('form').submit((e) -> e.preventDefault())
		['#calendarday','#group_popup'].forEach((id) -> $(id).on('hidden.bs.modal', (_) -> (if state.callbacks.close_popup then state.callbacks.close_popup(state))))
	render_taglists = () ->
		Object.keys(state.verbose.contacts).forEach((k) ->
			if document.getElementById('contacts-list-'+k)
				id = '#contacts-list-'+k
				$(id).tagsinput({trimValue: true})
				if (k == "phones")
					$(id).on('beforeItemAdd', (e) -> if not(utils.check_phone(e.item)) then e.cancel = true))
	render_tables = require("tablesorter")
	require("main")(state, utils)
