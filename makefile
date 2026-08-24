NAME =          pestilence
CC =            gcc
CFLAGS =        


NASM =          nasm
NASM_FLAGS =    -f bin # Default for Linux ELF stubs

SRC_DIR =       src
UTIL_DIR =      src/utils
STUB_DIR =      stubs

STUB_SRC =      $(wildcard $(STUB_DIR)/*.s)
STUB_BIN =      $(STUB_SRC:.s=.bin)

SRC =           main.c $(wildcard $(SRC_DIR)/*.c) $(wildcard $(UTIL_DIR)/*.c)
OBJ =           $(SRC:.c=.o)

all: $(NAME) stub

$(NAME): $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o $(NAME)

%.o: %.c pestilence.h
	$(CC) $(CFLAGS) -c $< -o $@

stub: $(STUB_BIN)


$(STUB_DIR)/%.bin: $(STUB_DIR)/%.s
	$(NASM) $(NASM_FLAGS) $< -o $@

clean:
	rm -f $(OBJ) pestilence stubs/*.bin 

fclean: clean
	rm -f $(NAME) 

re: fclean all

.PHONY: all clean fclean re stub