NULL =
INSTALL_DATA_DIR = /usr/local/share/gnome-slack
INSTALL_BIN_DIR  = /usr/local/bin
SUBDIRS =	\
	src 	\
	data 	\
	$(NULL)

all: 
	list='$(SUBDIRS)'; for dir in $$list; do  				\
		if test -d $$dir; then 								\
			cd "$$dir"; 									\
			if test -f "Makefile"; then 					\
				make ;										\
			fi ;											\
			cd ".." ; 										\
		fi 													\
	done  

install: all
	if ! test -d "$(INSTALL_DATA_DIR)"; then 				\
		echo "Creating $(INSTALL_DATA_DIR)" ; 				\
		mkdir "$(INSTALL_DATA_DIR)" ; 						\
	fi 
	
	cp src/gnome-slack "$(INSTALL_BIN_DIR)"
	cp data/Slack_Icon.png "$(INSTALL_DATA_DIR)"
	
uninstall:
	if test -f "$(INSTALL_DATA_DIR)/Slack_Icon.png"; then 	\
		rm -f "$(INSTALL_DATA_DIR)/Slack_Icon.png" ; 		\
	fi
	
	rmdir "$(INSTALL_DATA_DIR)"
	rm -f "$(INSTALL_BIN_DIR)/gnome-slack"
	
clean:
	rm -f src/gnome-slack

