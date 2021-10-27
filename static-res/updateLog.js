require(['dojo/ready', 'dojox/cometd', 'dojo/dom', 'dojo', 'dojo/query'], function(ready){
	ready(function(){
		
		
		var auth = 'OAuth ' + token;
		var cometdURL = window.location.protocol+'//'+window.location.hostname+ (null != window.location.port ? (':'+window.location.port) : '') +'/cometd/53.0/';
		var eventChannel = '/event/Update_Owner_Event__e';
		var connected = false;
		var eventSubscription = false;
		var cometd = dojox.cometd;
		var isTaskCompleted = false;
		var callCounter = 0;
		
		function metaConnectListener(message) {
			var wasConnected = connected;
			connected = message.successful;
			if (!wasConnected && connected) {   
				subscribe();
				console.debug('UPDATE_LOG DEBUG: Connection is successful');
			} else if (wasConnected && !connected) {
				console.debug('UPDATE_LOG DEBUG: Disconnected from the server');
			}
		};

		function metaHandshakeListener(message) {
			if (message.successful) {
				console.debug('UPDATE_LOG DEBUG: Handshake successful');
			} else {
				console.debug('UPDATE_LOG DEBUG: Handshake unsuccessful');
			}
		};

		function metaDisconnectListener(message) {
			console.debug('UPDATE_LOG DEBUG: /meta/disconnect message');
			console.dir(message);
		};

		function metaSubscribeListener(message) {  
			if (message.successful) {
				console.debug('UPDATE_LOG DEBUG: Subscribe successful ' + eventChannel);
			} else {
				console.debug('UPDATE_LOG DEBUG: Subscribe unsuccessful ' + eventChannel);
			}    
		};

		function metaUnSubscribeListener(message) {  
			if (message.successful) {
				console.debug('UPDATE_LOG DEBUG: Unsubscribe Successful ' + eventChannel);
			} else {
				console.debug('UPDATE_LOG DEBUG: Unsubscribe Unsuccessful ' + eventChannel);                
			}
		};

		function metaUnSucessfulListener(message) {  
			console.debug('UPDATE_LOG DEBUG:  /meta/unsuccessful Error:');
			console.dir(message);
		};

		function subscribe() {  
			if(connected) {
				eventSubscription = cometd.subscribe(eventChannel, receive);	
			} else {
				console.debug('UPDATE_LOG DEBUG: Cannot subscribe due to unsuccessful connection');
			}                
		};

		function receive(message) {
			if (isTaskCompleted) {
				updateLog = '';
				isTaskCompleted = false;
			}
			callCounter++;
			data = message.data.payload;
			updateLog += JSON.stringify(data, null, '\t');
			updateLog += 'END_OF_MSG';
			if (data.jobStatus__c.includes('Final')) {
				relayJobState(updateLog);
				isTaskCompleted = true;
				callCounter = 0;
			}			
			console.debug('UPDATE_LOG DEBUG: ' + JSON.stringify(data, null, '\t'));
		};
				
		cometd.websocketEnabled = false;
		cometd.configure({
			url: cometdURL,
			requestHeaders: { Authorization: auth},
			appendMessageTypeToURL : false
		});

		cometd.addListener('/meta/connect', metaConnectListener);

		cometd.addListener('/meta/handshake', metaHandshakeListener);

		cometd.addListener('/meta/disconnect', metaDisconnectListener);

		cometd.addListener('/meta/subscribe', metaSubscribeListener);

		cometd.addListener('/meta/unsubscribe', metaUnSubscribeListener);

		cometd.addListener('/meta/unsuccessful', metaUnSucessfulListener);

		cometd.handshake();
		
	});
});
