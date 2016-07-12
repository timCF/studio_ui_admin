document.addEventListener "DOMContentLoaded", (e) ->
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
		dayClick: ((date, _, __) -> state.workday = date ; $('#datepair .date.start').datepicker('setDate', date.toDate()) ; $('#calendarday').modal()),
		eventAfterRender: ((data, element, _) -> $(element).css('width', ($(element).width() * data.percentfill) + 'px')),
		events: [
			{
				title: 'event1',
				start: '2016-06-01',
				percentfill: 0.5
			},
			{
				title: 'event2',
				start: '2016-06-05',
				end: '2016-06-07',
				percentfill: 0.2
			},
			{
				title: 'event5',
				start: '2016-06-05',
				end: '2016-06-07',
				percentfill: 0.2
			},
			{
				title: 'event5',
				start: '2016-06-05',
				end: '2016-06-07',
				percentfill: 0.2
			},
			{
				title: 'event5',
				start: '2016-06-05',
				end: '2016-06-07',
				percentfill: 0.2
			},
			{
				title: 'event5',
				start: '2016-06-05',
				end: '2016-06-07',
				percentfill: 0.2
			},
			{
				title: 'event5',
				start: '2016-06-05',
				end: '2016-06-07',
				percentfill: 0.2
			},
			{
				title: 'event5',
				start: '2016-06-05',
				end: '2016-06-07',
				percentfill: 0.2
			},
			{
				title: 'event3',
				start: '2016-06-09T12:30:00',
				allDay: false
				percentfill: 0.9
			}
		]
	}
	# state for main function, mutable
	state = {
		opts: {},
		data: {},
		# current data
		ids: {
			location: false,
			room: false
		},
		request_template: false,
		response_state: false,
		workday: moment(),
		datepair: false,
		calendar: false,
		datepairval: {
			date: {start: '', end: ''},
			time: {start: '', end: ''}
		}
	}
	render = () ->
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
	render_datepair = () ->
		datepair = document.getElementById('datepair')
		if not(datepair) then (state.datepair = false)
		if not(state.datepair) and datepair
			$('#datepair .time').timepicker(timepicker_opts)
			$('#datepair .date').datepicker(datepicker_opts)
			state.datepair = new Datepair(datepair, {defaultTimeDelta: 10800000})
			$('#datepair').on('rangeSelected', () ->
				state.datepairval.date.start = $('#datepair .date.start').datepicker('getDate')
				state.datepairval.date.end = $('#datepair .date.end').datepicker('getDate')
				state.datepairval.time.start = $('#datepair .time.start').timepicker('getTime')
				state.datepairval.time.end = $('#datepair .time.end').timepicker('getTime'))
			console.log("render datepair")
	render_calendar = () ->
		calendar = document.getElementById('calendar')
		if not(calendar) then (state.calendar = false)
		if not(state.calendar) and calendar
			state.calendar = $(calendar).fullCalendar(calendar_opts)
			console.log("render calendar")
	render_tooltips = () ->
		$('[data-toggle="tooltip"]').tooltip()
		out = $(".tooltip").attr('id')
		if out and ($("[aria-describedby='"+out+"']").length == 0)
			$( document.getElementById(out) ).remove()
			console.log("destroy tooltip "+out)
	render_jqcb = () ->
		# NOTICE !!! not reload page on submit forms
		$('form').submit((e) -> e.preventDefault())
	require("main")(state, utils)
