curl --dump-header cookies.txt http://localhost:6000/login
curl --cookie cookies.txt http://localhost:5000/
curl --cookie cookies.txt http://localhost:7000/logout