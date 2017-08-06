docker stop $(docker ps -aqf "ancestor=starsonkitura") &> /dev/null && docker rm $(docker ps -aqf "ancestor=starsonkitura") &> /dev/null
docker build -t starsonkitura . &&
docker run -d -p 8080:8080 starsonkitura &&
docker exec -it `docker ps -aqf "ancestor=starsonkitura"` bash -c 'StarsOnKitura'
