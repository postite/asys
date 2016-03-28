package sys.async.io;

#if nodejs
import js.node.Fs;
import js.node.fs.Stats;
#end
import sys.async.io.FileInput;
import sys.async.io.FileOutput;
import tink.io.Sink;
import tink.io.Source;

using tink.CoreApi;

@:build(asys.Builder.build())
class File {

	public static function getContent(path: String): Surprise<String, Error> {
		var trigger = Future.trigger();
		Fs.readFile(path, 'utf8', function(err: js.Error, data: String)
			trigger.trigger(switch err {
				case null: Success(data);
				default: Failure(Error.withData(err.message, err));
			})
		);
		return trigger.asFuture();
	}

	public static function saveContent(path: String, content: String): Surprise<Noise, Error> {
		var trigger = Future.trigger();
		Fs.writeFile(path, untyped content, 'utf8', function(err: js.Error)
			trigger.trigger(switch err {
				case null: Success(Noise);
				default: Failure(Error.withData(err.message, err));
			})
		);
		return trigger.asFuture();
	}

	public static function getBytes(path: String): Surprise<haxe.io.Bytes, Error> {
		var trigger = Future.trigger();
		Fs.readFile(path, function(err: js.Error, buffer: js.node.Buffer)
			trigger.trigger(switch err {
				case null: Success(buffer.hxToBytes());
				default: Failure(Error.withData(err.message, err));
			})
		);
		return trigger.asFuture();
	}

	public static function saveBytes(path: String, bytes: haxe.io.Bytes): Surprise<Noise, Error> {
		var trigger = Future.trigger();
		Fs.writeFile(path, js.node.Buffer.hxFromBytes(bytes), function(err: js.Error)
			trigger.trigger(switch err {
				case null: Success(Noise);
				default: Failure(Error.withData(err.message, err));
			})
		);
		return trigger.asFuture();
	}

	public static function read(path: String, binary = true): Surprise<FileInput, Error> {
		var trigger = Future.trigger();
		Fs.open(path, 'r', function(err: js.Error, fd: Int)
			trigger.trigger(switch err {
				case null: Success(new FileInput(fd));
				default: Failure(Error.withData(err.message, err));
			})
		);
		return trigger.asFuture();
	}

	public static function write(path : String, binary: Bool = true): Surprise<FileOutput, Error> {
		var trigger = Future.trigger();
		Fs.open(path, 'w', function(err: js.Error, fd: Int)
			trigger.trigger(switch err {
				case null: Success(new FileOutput(fd));
				default: Failure(Error.withData(err.message, err));
			})
		);
		return trigger.asFuture();
	}
	
	public static function readStream(path: String, binary = true): Source {
		#if nodejs
		return Source.ofNodeStream(Fs.createReadStream(path), 'asys read stream');
		#else
		return Source.ofInput('asys read stream', sys.io.File.read(path));
		#end
	}

	public static function writeStream(path : String, binary: Bool = true): Sink {
		#if nodejs
		return Sink.ofNodeStream(Fs.createWriteStream(path), 'asys write stream');
		#else
		return Sink.ofOutput('asys write stream', sys.io.File.write(path));
		#end
	}

	public static function append( path : String, binary : Bool = true ): Surprise<FileOutput, Error> {
		var trigger = Future.trigger();
		Fs.open(path, 'a', function(err: js.Error, fd: Int)
			trigger.trigger(switch err {
				case null: Success(new FileOutput(fd));
				default: Failure(Error.withData(err.message, err));
			})
		);
		return trigger.asFuture();
	}

	public static function copy(srcPath: String, dstPath: String): Surprise<Noise, Error> {
		var trigger = Future.trigger();
		var called = false;
		function done(?err: js.Error) {
			if (called) return;
			switch err {
				case null: Success(Noise);
				default: Failure(Error.withData(err.message, err));
			}
			called = true;
		}
		var rd = Fs.createReadStream(srcPath);
		rd.on('error', done);
		var wr = Fs.createWriteStream(dstPath);
		wr.on('error', done);
		wr.on('close', function(ex) {
			done();
		});
		rd.pipe(wr);
		
		return trigger.asFuture();
	}
}