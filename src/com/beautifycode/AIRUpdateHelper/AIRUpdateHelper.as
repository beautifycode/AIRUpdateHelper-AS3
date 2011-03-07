package com.beautifycode.AIRUpdateHelper
{
	import flash.desktop.NativeApplication;
	import flash.desktop.Updater;
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
	public class AIRUpdateHelper
	{
		/**
		 * @private
		 */
		private static var _updateFileLocation : String;
		/**
		 * @private
		 */
		private static var _availableVersion : String;
		/**
		 * @private
		 */
		private static var _downloadLocation : String;
		/**
		 * @private
		 */
		private static var _forceUpdate : Boolean;
		/**
		 * @private
		 */
		private static var _changeLog : String;

		/**
		 * @private
		 */
		private static var _failHandler : Function;
		/**
		 * @private
		 */
		private static var _skipHandler : Function;

		/**
		 * @private
		 */
		private static var _appName : String;
		/**
		 * @private
		 */
		private static var _currentVersion : String;

		/**
		 * @private
		 */
		private static var _updateFilePathLoader : URLLoader;
		/**
		 * @private
		 */
		private static var _downloadLoader : URLLoader;

		/**
		 * AIRUpdateHelper
		 * 
		 * @throws AIRUpdateHelper cannot be constructed.
		 */
		public function AIRUpdateHelper()
		{
			throw new Error("AIRUpdateHelper cannot be constructed.");
		}

		/**
		 * Check for new update.
		 * 
		 * @param updateFileLocation Path to XML file with versioning info.
		 * @param skipHandler Callback called once the user decides not to update. No arguments.
		 * @param failHandler Callback called once something goes wrong. One argument <code>errMsg : String</code>
		 */
		public static function checkForUpdate(updateFileLocation : String, skipHandler : Function = null, failHandler : Function = null) : void
		{
			destroy();

			_updateFileLocation = updateFileLocation;

			_skipHandler = skipHandler;
			_failHandler = failHandler;

			_loadUpdateData();
		}

		/**
		 * Gets basic info about the current app.
		 * 
		 * @return Object with two properties <code>version</code> and <code>name</code>. 
		 */
		public static function getAppInfo() : Object
		{
			var appXml : XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns : Namespace = appXml.namespace();

			var appInfoObj : Object = new Object();
			appInfoObj.version = appXml.ns::version[0];
			appInfoObj.name = appXml.ns::name[0];

			return appInfoObj;
		}

		/**
		 * Destroys all references and removes all internal listeners. Doubles as a "cancel" function.
		 * <p><strong>Note:</strong> AIRUpdateHelper#checkForUpdate will still work after calling destroy.</p>
		 */
		public static function destroy() : void
		{
			_skipHandler = null;
			_failHandler = null;

			if(_updateFilePathLoader)
			{
				_updateFilePathLoader.removeEventListener(Event.COMPLETE, _updateFileLoaded);
				_updateFilePathLoader.removeEventListener(IOErrorEvent.IO_ERROR, _onDownloadFail);
				try
				{
					_updateFilePathLoader.close();
				}
				catch(error : Error)
				{
				}
				_updateFilePathLoader = null;
			}

			if(_downloadLoader)
			{
				_downloadLoader.removeEventListener(Event.COMPLETE, _writeFileToSystem);
				_downloadLoader.removeEventListener(IOErrorEvent.IO_ERROR, _onDownloadFail);
				try
				{
					_downloadLoader.close();
				}
				catch(error : Error)
				{
				}
				_downloadLoader = null;
			}
		}

		/**
		 * @private
		 */
		private static function _loadUpdateData() : void
		{
			_updateFilePathLoader = new URLLoader();
			_updateFilePathLoader.addEventListener(Event.COMPLETE, _updateFileLoaded);
			_updateFilePathLoader.addEventListener(IOErrorEvent.IO_ERROR, _onDownloadFail);
			_updateFilePathLoader.load(new URLRequest(_updateFileLocation));
		}

		/**
		 * @private
		 */
		private static function _updateFileLoaded(event : Event) : void
		{
			var appInfo : Object = getAppInfo();
			_appName = appInfo.name;
			_currentVersion = appInfo.version;

			var updateFileXML : XML = new XML(_updateFilePathLoader.data);
			_availableVersion = updateFileXML.version;
			_downloadLocation = updateFileXML.downloadLocation;
			_forceUpdate = Boolean(updateFileXML.forceUpdate == "true");
			_changeLog = updateFileXML.message;

			if(_currentVersion != _availableVersion)
			{
				if(!_forceUpdate)
					AIRUpdateUI.createUpdateDialog(_appName, _currentVersion, _availableVersion, _changeLog, _confirmHandler, _cancelHandler);
				else
					AIRUpdateUI.createForceUpdateDialog(_appName, _currentVersion, _availableVersion, _changeLog, _confirmHandler);
			}
			else
				_cancelHandler(null);
		}

		/**
		 * @private
		 */
		private static function _cancelHandler(event : MouseEvent) : void
		{
			AIRUpdateUI.close();
			if(_skipHandler != null)
				_skipHandler();

			destroy();
		}

		/**
		 * @private
		 */
		private static function _confirmHandler(event : MouseEvent) : void
		{
			_downloadLoader = new URLLoader();
			_downloadLoader.dataFormat = URLLoaderDataFormat.BINARY;
			_downloadLoader.addEventListener(Event.COMPLETE, _writeFileToSystem);
			_downloadLoader.addEventListener(IOErrorEvent.IO_ERROR, _onDownloadFail);
			_downloadLoader.load(new URLRequest(_downloadLocation));

			// @TODO: ProgressHandler
			// loader.addEventListener(ProgressEvent.PROGRESS, _updateProgressHandler);
		}

		/**
		 * @private
		 */
		private static function _onDownloadFail(event : IOErrorEvent) : void
		{
			if(_failHandler != null)
				_failHandler("There was an error loading your remote version-config file.");

			destroy();
		}

		/**
		 * @private
		 */
		private static function _writeFileToSystem(event : Event) : void
		{
			try
			{
				var filename : String = _downloadLocation.split("/").pop() as String;
				var file : File = File.documentsDirectory.resolvePath(filename);
				var stream : FileStream = new FileStream();
				stream.open(file, FileMode.WRITE);
				stream.writeBytes(event.target.data);
				stream.close();

				_installUpdate(file);
			}
			catch (error : Error)
			{
				if(_failHandler != null)
					_failHandler("The downloaded file was not written correctly.");
			}

			destroy();
		}

		/**
		 * @private
		 */
		private static function _installUpdate(file : File) : void
		{
			var updater : Updater = new Updater();
			updater.update(file, _availableVersion);
		}
	}
}
