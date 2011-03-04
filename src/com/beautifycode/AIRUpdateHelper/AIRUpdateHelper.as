package com.beautifycode.AIRUpdateHelper {
	import flash.desktop.NativeApplication;
	import flash.desktop.Updater;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;

	/**
	 * @author Marvin
	 */
	public class AIRUpdateHelper {
		private static var _updateFileLocation : String;
		private static var _forceUpdate : Boolean;
		private static var _downloadLocation : String;
		private static var _changeLog : String;
		private static var _callbackStage : DisplayObjectContainer;
		private static var _failHandler : Function;
		private static var _skipHandler : Function;
		private static var _availableVersion : String;
		private static var _currentVersion : String;
		private static var _appName : String;

		public function AIRUpdateHelper() {
		}

		public static function checkForUpdate(updateFileLocation : String, callbackStage : DisplayObjectContainer, skipHandler : Function = null, failHandler : Function = null) : void {
			_updateFileLocation = updateFileLocation;
			_callbackStage = callbackStage;

			_skipHandler = skipHandler;
			_failHandler = failHandler;

			_loadUpdateData();
		}

		private static function _loadUpdateData() : void {
			var _updateFilePathReq : URLRequest = new URLRequest(_updateFileLocation);

			var _updateFilePathLoader : URLLoader = new URLLoader();
			_updateFilePathLoader.load(_updateFilePathReq);
			_updateFilePathLoader.addEventListener(Event.COMPLETE, _updateFileLoaded);
			_updateFilePathLoader.addEventListener(IOErrorEvent.IO_ERROR, _onDownloadFail);
		}

		private static function _updateFileLoaded(event : Event) : void {
			_appName = getAppInfos().name;
			_currentVersion = getAppInfos().version;

			var updateFileXML : XML = new XML(event.target.data);
			_availableVersion = updateFileXML.version;
			_downloadLocation = updateFileXML.downloadLocation;
			_forceUpdate = Boolean(updateFileXML.forceUpdate == "true");
			_changeLog = updateFileXML.message;

			if (Number(_availableVersion) > Number(_currentVersion)) {
				if (!_forceUpdate) AIRUpdateUI.createUpdateDialog(_appName, _currentVersion, _availableVersion, _changeLog, _confirmHandler, _cancelHandler);
				else AIRUpdateUI.createForceUpdateDialog(_appName, _currentVersion, _availableVersion, _changeLog, _confirmHandler);
			} else {
				_cancelHandler(null);
			}
		}

		private static function _cancelHandler(event : MouseEvent) : void {
			AIRUpdateUI.close();
			_skipHandler();
		}

		private static function _confirmHandler(event : MouseEvent) : void {
			var donwloadRequest : URLRequest = new URLRequest(_downloadLocation);
			var downloadLoader : URLLoader = new URLLoader();
			downloadLoader.dataFormat = URLLoaderDataFormat.BINARY;
			downloadLoader.load(donwloadRequest);
			downloadLoader.addEventListener(Event.COMPLETE, _writeFileToSystem);
			downloadLoader.addEventListener(IOErrorEvent.IO_ERROR, _onDownloadFail);

			// @TODO: ProgressHandler
			// loader.addEventListener(ProgressEvent.PROGRESS, _updateProgressHandler);
		}

		private static function _onDownloadFail(event : *) : void {
			_failHandler("There was an error loading your remote version-config file.");
		}

		private static function _writeFileToSystem(event : Event) : void {
			try {
				var filename : String = _downloadLocation.split("/").pop() as String;
				var file : File = File.documentsDirectory.resolvePath(filename);
				var stream : FileStream = new FileStream();
				stream.open(file, FileMode.WRITE);
				stream.writeBytes(event.target.data);
				stream.close();

				_installUpdate(file);
			} catch (error : Error) {
				_failHandler("The downloaded file was not written correctly.");
			}
		}

		private static function _installUpdate(file : File) : void {
			var updater : Updater = new Updater();
			updater.update(file, _availableVersion);
		}

		public static function getAppInfos() : Object {
			var appXml : XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns : Namespace = appXml.namespace();

			var appInfoObj : Object = new Object();
			appInfoObj.version = appXml.ns::version[0];
			appInfoObj.name = appXml.ns::name[0];

			return appInfoObj;
		}
	}
}
