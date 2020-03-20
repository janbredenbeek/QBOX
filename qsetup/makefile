
CFLAGS = -v -O -warn=5 -tmpram1_

OBJS = main_o filenames_o mailer_o users_o misc_o modem_o

# SRCS = main_c filenames_c mailer_c users_c misc_c modem_c

qsetup: $(OBJS)
   ld -v -o$Cqsetup $(OBJS) -lwamm

$(OBJS): qsetup_h

