
all: 
	valac \
		--pkg gtk+-3.0       \
		--pkg gio-2.0        \
		--pkg webkit2gtk-4.0 \
		--thread             \
		gnome-slack.vala
