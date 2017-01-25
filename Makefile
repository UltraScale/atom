
include linux_headers glibc ncurses readline bash



sources:
	cd sources
	wget -l -nc -c wget-list

kernel: sources



system: sources


check: ## Esto es para chequear que existen los simbolic link, que todos los binarios son ARM, etc
