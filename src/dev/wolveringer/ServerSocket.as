package dev.wolveringer
{
    import flash.net.Socket;
    import flash.utils.ByteArray;
    import flash.events.Event;
    import flash.events.ProgressEvent;
    import flash.events.IOErrorEvent;

    public class ServerSocket
    {
        public static var instance: ServerSocket;

        public var host:String;
        public var port:Number;

        private var socket:Socket;
        private var socketBuffer:ByteArray;
        private var socketCommandHandler:Object;

        public function ServerSocket(host:String, port:Number) {
            this.host = host;
            this.port = port;

            this.socketBuffer = new ByteArray();
            this.socketCommandHandler = { };
        }

        public function registerCommandHandler(command:String, handler:Function): void {
            this.socketCommandHandler[command] = handler;
        }

        public function connect():void {
            //this.spawnSocket();
        }

        private function spawnSocket():void
        {
            if (this.socket)
            {
                this.socket.close();
            }

            this.socket = new Socket();
            this.socketBuffer.clear();

            this.socket.connect(this.host, this.port);
            this.socket.timeout = 1000;
            this.socket.addEventListener(ProgressEvent.SOCKET_DATA, this.onSocketData);
            this.socket.addEventListener(Event.CONNECT, this.onSocketConnected);
            this.socket.addEventListener(Event.CLOSE, this.onSocketClose);
            this.socket.addEventListener(IOErrorEvent.IO_ERROR, this.onSocketError);
            // this.socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR,this.securityError);
        }

        private function onSocketData(param1:Event):void
        {
            this.socket.readBytes(this.socketBuffer, this.socketBuffer.length);
            this.processSocketBuffer();
        }
        private function onSocketClose(param1:Event):void
        {
            trace("Socket disconnected.");
            this.spawnSocket();
        }

        private function onSocketError(param1:Event):void
        {
            trace("Socket error", param1);
            this.spawnSocket();
        }

        private function onSocketConnected(param1:Event):void
        {
            trace("Socket connected");
            this.sendSocketCommand("hello-world", {});
            /* FIXME: Send battle & map data */
        }

        private function processSocketBuffer():void
        {
            while (this.socketBuffer.bytesAvailable > 4)
            {
                const length:Number = this.socketBuffer.readInt();
                if (this.socketBuffer.bytesAvailable < length)
                {
                    this.socketBuffer.position = 0;
                    break;
                }

                const command:* = JSON.parse(
                    this.socketBuffer.readUTFBytes(length)
                    );

                const handler:* = this.socketCommandHandler[command.type];
                if (handler)
                {
                    handler(JSON.parse(command["payload"]));
                }
                else
                {
                    trace("Unknown command " + command.type);
                }
            }

            this.socketBuffer.clear();
        }

        public function sendSocketCommand(command:String, payload:*):void
        {
            if(!this.socket) {
                return;
            }
            
            const encoded:String = JSON.stringify( {
                    "type": command,
                    "payload": JSON.stringify(payload)
                });
            this.socket.writeInt(encoded.length);
            this.socket.writeUTFBytes(encoded);
            this.socket.flush();
        }
    }
}