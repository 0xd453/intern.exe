extends Node

@warning_ignore("unused_signal")
signal message_arrived(contact: String)

@warning_ignore("unused_signal")
signal tutorial_event(name: String)

@warning_ignore("unused_signal")
signal case_resolved(id: String)

@warning_ignore("unused_signal")
signal day_started(n: int)

@warning_ignore("unused_signal")
signal day_done(n: int)


@warning_ignore("unused_signal")
signal end_workday_requested

@warning_ignore("unused_signal")
signal restart_requested

@warning_ignore("unused_signal")
signal message_delivered(msg: Dictionary)

@warning_ignore("unused_signal")
signal chat_notification_changed

@warning_ignore("unused_signal")
signal clock_changed
