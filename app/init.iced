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
		workday: moment(),
		datepair: false,
		calendar: false,
		datepairval: {
			date: {start: '', end: ''},
			time: {start: '', end: ''}
		}
	}
	# some compile-time defined utils, frozen
	utils = Object.freeze(tmp = require("utils") ; tmp.proto = require("protobufjs").loadProtoFile("./studio_proto/studio.proto").build("lemooor.studio") ; tmp)
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
	render = () ->
		render_datepair()
		render_calendar()
		react.render(widget(fullstate), document.getElementById("main_frame"))
		setTimeout(render, 500)
	require("main")(state, utils)
	render()
