const messages = document.getElementById('messages');
const messageInput = document.getElementById('message-input');
const sendButton = document.getElementById('send-button');

const userId = prompt("Enter your user ID:");
if (!userId) {
    alert("User ID is required to connect.");
}

const socket = new WebSocket(`YOUR_WEBSOCKET_URI?userId=${userId}`);

socket.addEventListener('open', (event) => {
    console.log('WebSocket is open now.');
});

socket.addEventListener('close', (event) => {
    console.log('WebSocket is closed now.');
});

socket.addEventListener('error', (event) => {
    console.error('WebSocket error: ', event);
});

socket.addEventListener('message', (event) => {
    const messageData = JSON.parse(event.data);
    const messageElement = document.createElement('li');
    messageElement.textContent = `${messageData.user}: ${messageData.message}`;

    if (messageData.sentiment > 0.5) {
        messageElement.classList.add('positive');
    } else if (messageData.sentiment < -0.5) {
        messageElement.classList.add('negative');
    } else {
        messageElement.classList.add('neutral');
    }

    messages.appendChild(messageElement);
    messages.scrollTop = messages.scrollHeight;
});

sendButton.addEventListener('click', () => {
    const message = messageInput.value;
    if (message) {
        const payload = {
            action: 'sendmessage',
            message: message
        };
        socket.send(JSON.stringify(payload));
        messageInput.value = '';
    }
});

messageInput.addEventListener('keypress', (event) => {
    if (event.key === 'Enter') {
        sendButton.click();
    }
});