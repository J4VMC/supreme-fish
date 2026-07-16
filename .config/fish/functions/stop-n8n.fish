function stop-n8n --description 'Stop and remove the n8n Docker container'
    echo "Stopping n8n..."
    docker stop n8n
    echo "Cleaning up container..."
    docker rm n8n
    echo "n8n has been stopped safely."
end
