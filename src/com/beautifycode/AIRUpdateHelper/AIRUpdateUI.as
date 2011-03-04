package com.beautifycode.AIRUpdateHelper {
	import com.bit101.components.TextArea;

	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowType;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	/**
	 * @author Marvin
	 */
	public class AIRUpdateUI extends Sprite {
		private static var _uiWindow : NativeWindow;
		private static var _changeLogTextArea : TextArea;
		private static var _uiWindowOptions : NativeWindowInitOptions;
		private static var _uiContainer : UIContainer;

		public function AIRUpdateUI() {
		}

		public static function createUpdateDialog(appName : String, currentVersion : String, availableVersion : String, changeLog : String, confirmHandler : Function, skipHandler : Function) : void {
			_changeLogTextArea = new TextArea();
			_changeLogTextArea.x = 17;
			_changeLogTextArea.y = 245;
			_changeLogTextArea.width = 500;
			_changeLogTextArea.height = 85;
			_changeLogTextArea.editable = false;
			_changeLogTextArea.text = changeLog;

			_uiContainer = new UIContainer();
			_uiContainer.appNameTF.text = appName;
			_uiContainer.currentVersionTF.text = currentVersion;
			_uiContainer.availableVersionTF.text = availableVersion;
			_uiContainer.addChild(_changeLogTextArea);

			_uiContainer.confirmBtn.addEventListener(MouseEvent.CLICK, confirmHandler);
			_uiContainer.skipBtn.addEventListener(MouseEvent.CLICK, skipHandler);

			_uiWindowOptions = new NativeWindowInitOptions();
			_uiWindowOptions.type = NativeWindowType.NORMAL;
			_uiWindowOptions.resizable = false;
			_uiWindowOptions.maximizable = false;

			_uiWindow = new NativeWindow(_uiWindowOptions);
			_uiWindow.minSize = new Point(530, 365);
			_uiWindow.width = 530;
			_uiWindow.height = 365;
			_uiWindow.title = "Update for " + appName + " available!";

			_uiWindow.stage.scaleMode = StageScaleMode.NO_SCALE;
			_uiWindow.stage.align = StageAlign.TOP_LEFT;
			_uiWindow.stage.addChild(_uiContainer);
			_uiWindow.activate();
			_uiWindow.orderToFront();
		}

		public static function createForceUpdateDialog(appName : String, currentVersion : String, availableVersion : String, changeLog : String, confirmHandler : Function) : void {
			// @TODO: quit instead of skip button, red cross icon
		}

		public static function close() : void {
			_uiWindow.close();
		}
	}
}
