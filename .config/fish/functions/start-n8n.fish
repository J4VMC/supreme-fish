function start-n8n --description 'Start n8n in a detached Docker container'
    docker run -d \
	--name n8n \
	--restart unless-stopped \
	-p 5678:5678 \
	-e GENERIC_TIMEZONE="Europe/Stockholm" \
	-e TZ="Europe/Stockholm" \
	-v n8n_data:/home/node/.n8n \
	docker.n8n.io/n8nio/n8n
end
