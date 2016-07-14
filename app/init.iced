document.addEventListener "DOMContentLoaded", (e) ->
	jf = require("jsfunky")
	timepicker_opts = {
		minTime: "9:00"
		timeFormat: 'H:i',
		disableTextInput: true,
		disableTouchKeyboard: true,
		show2400: true,
		step: 15
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
		lang: 'ru',
		firstDay: 1,
		dayClick: ((date, _, __) ->
			if state.ids.room
				state.datepairval.time.start = ''
				state.datepairval.time.end = ''
				state.new_session = utils.new_session(state)
				state.workday = false
				utils.render() # reset popup to reset content
				state.workday = date
				utils.render()
				utils.render() # rerender new popup some times ( somewhere is async shit )
				$('#datepair .time.start').timepicker('setTime', '')
				$('#datepair .time.end').timepicker('setTime', '')
				$('#datepair .date.start').datepicker('setDate', date.toDate())
				utils.render()
				$('#calendarday').modal()
			else
				utils.error("не выбрана комната")),
		eventAfterRender: ((data, element, _) -> $(element).css('width', ($(element).width() * data.percentfill) + 'px'))
		eventClick: (({id: id}, _, __) ->
			state.new_session = utils.clone_proto(state.response_state.sessions.filter(({id: this_id}) -> this_id.compare(id) == 0)[0], "Session")
			state.workday = false
			utils.render() # reset popup to reset content
			state.workday = moment(state.new_session.time_from.toString() * 1000)
			utils.render()
			utils.render() # rerender new popup some times ( somewhere is async shit )
			ds = moment(state.new_session.time_from.toString() * 1000).toDate()
			de = moment(state.new_session.time_to.toString() * 1000).toDate()
			$('#datepair .date.start').datepicker('setDate', ds)
			$('#datepair .date.end').datepicker('setDate', de)
			$('#datepair .time.start').timepicker('setTime', ds)
			$('#datepair .time.end').timepicker('setTime', de)
			utils.render()
			new_datepairval()
			$('#calendarday').modal())
	}
	# state for main function, mutable
	state = {
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
		current_page: "calendar_main"
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
		verbose: require("verbose")
	}
	render = () ->
		state.dimensions.height = window.innerHeight
		state.dimensions.width = window.innerWidth
		render_datepair()
		render_calendar()
		render_tooltips()
		render_jqcb()
		react.render(widget(fullstate), document.getElementById("main_frame"))
	render_coroutine = () ->
		render()
		setTimeout(render_coroutine, 500)
	# some compile-time defined utils, frozen
	utils = Object.freeze(tmp = require("bullet")(require("proto")(require("utils")), state) ; tmp.render = render ; tmp.render_coroutine = render_coroutine ; tmp)
	# full state structure, frozen
	fullstate = Object.freeze({state: state, utils: utils})
	react = require("react-dom")
	widget = require("widget")
	new_datepairval = () ->
		console.log("new datepairval")
		state.datepairval.date.start = $('#datepair .date.start').datepicker('getDate')
		state.datepairval.date.end = $('#datepair .date.end').datepicker('getDate')
		state.datepairval.time.start = $('#datepair .time.start').timepicker('getTime')
		state.datepairval.time.end = $('#datepair .time.end').timepicker('getTime')
	render_datepair = () ->
		datepair = document.getElementById('datepair')
		if not(datepair) then (state.datepair = false)
		if not(state.datepair) and datepair
			$('#datepair .time').timepicker(timepicker_opts)
			$('#datepair .date').datepicker(datepicker_opts)
			state.datepair = new Datepair(datepair, {defaultTimeDelta: 10800000})
			$('#datepair').on('rangeSelected', new_datepairval)
			console.log("render datepair")
	render_calendar = () ->
		calendar = document.getElementById('calendar')
		if not(calendar) then (state.calendar = false)
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
		# NOTICE !!! not reload page on submit forms
		$('form').submit((e) -> e.preventDefault())
	require("main")(state, utils)
