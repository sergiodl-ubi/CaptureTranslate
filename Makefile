.PHONY: project open archive

project:
	@command -v xcodegen >/dev/null || { echo "Install XcodeGen first: brew install xcodegen"; exit 1; }
	xcodegen generate

open: project
	open CaptureTranslator.xcodeproj

archive:
	cd .. && zip -r CaptureTranslator.zip CaptureTranslator -x 'CaptureTranslator/.git/*' 'CaptureTranslator/build/*' 'CaptureTranslator/DerivedData/*'
