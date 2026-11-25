cask "evendisplay" do
  version "1.0.0"
  sha256 "075aec94ef62c96f83d8290671f357640a9973fabaec9723e7c85aebc247323f"

  url "https://github.com/amulyagupta1278/EvenDisplay/releases/download/v#{version}/EvenDisplay-v#{version}.zip"
  name "EvenDisplay"
  desc "Reversible vertical band compensator, 50% gray uniformity tester, and IPS conditioner for MacBook displays"
  homepage "https://evendisplay.amulyagupta.in/"

  depends_on macos: ">= :ventura"

  app "EvenDisplay.app"

  zap trash: [
    "~/Library/Preferences/com.evendisplay.app.plist",
  ]
end
