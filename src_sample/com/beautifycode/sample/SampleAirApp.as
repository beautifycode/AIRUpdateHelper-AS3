package com.beautifycode.sample
{
	import com.beautifycode.AIRUpdateHelper.AIRUpdateHelper;

	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;

	/**
	 * @author Marvin
	 */
	[SWF(backgroundColor="#FFFFFF", frameRate="31", width="550", height="400")]
	public class SampleAirApp extends Sprite
	{
		private var _layout : AppLayout;

		public function SampleAirApp()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;

			addEventListener(Event.ADDED_TO_STAGE, onStageAdded);
		}

		private function onStageAdded(event : Event) : void
		{
			_layout = new AppLayout();
			_layout.versionTF.text = AIRUpdateHelper.getAppInfo().version;
			_layout.statusTF.text = "Waiting for user choice.";
			addChild(_layout);
			

			AIRUpdateHelper.checkForUpdate("http://labs.beautifycode.com/airUpdateHelper/version.xml", onSkip, onFail);
		}

		private function onSkip() : void
		{
			_layout.statusTF.text = "Update was skipped / No updates available!";
		}

		private function onFail(msg : String) : void
		{
			_layout.statusTF.text = msg;
		}
	}
}
