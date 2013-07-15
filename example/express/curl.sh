
echo "retrieving user from 7000..."
curl --dump-header cookies.txt http://localhost:7000/
sleep 2
echo "\n"
echo "logging in from 6000..."
curl --cookie cookies.txt  http://localhost:7000/login
sleep 2
echo "\n"
echo "retrieving user from 5000..."
curl --cookie cookies.txt http://localhost:7000/
sleep 2
echo "\n"
echo "logging out from 7000..."
curl --cookie cookies.txt http://localhost:7000/logout
sleep 2
echo "\n"
echo "retrieving user from 6000..."
curl --cookie cookies.txt http://localhost:7000/
echo
rm cookies.txt