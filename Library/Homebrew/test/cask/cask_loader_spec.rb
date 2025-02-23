# frozen_string_literal: true

describe Cask::CaskLoader, :cask do
  describe "::for" do
    let(:tap) { CoreCaskTap.instance }

    context "when a cask is renamed" do
      let(:old_token) { "version-newest" }
      let(:new_token) { "version-latest" }

      let(:api_casks) do
        [old_token, new_token].to_h do |token|
          hash = described_class.load(new_token).to_hash_with_variations
          json = JSON.pretty_generate(hash)
          cask_json = JSON.parse(json)

          [token, cask_json.except("token")]
        end
      end
      let(:cask_renames) do
        { old_token => new_token }
      end

      before do
        allow(Homebrew::API::Cask)
          .to receive(:all_casks)
          .and_return(api_casks)

        allow(tap).to receive(:cask_renames)
          .and_return(cask_renames)
      end

      context "when not using the API" do
        before do
          ENV["HOMEBREW_NO_INSTALL_FROM_API"] = "1"
        end

        it "warns when using the short token" do
          expect do
            expect(described_class.for("version-newest")).to be_a Cask::CaskLoader::FromPathLoader
          end.to output(/version-newest was renamed to version-latest/).to_stderr
        end

        it "warns when using the full token" do
          expect do
            expect(described_class.for("homebrew/cask/version-newest")).to be_a Cask::CaskLoader::FromPathLoader
          end.to output(/version-newest was renamed to version-latest/).to_stderr
        end
      end

      context "when using the API" do
        before do
          ENV.delete("HOMEBREW_NO_INSTALL_FROM_API")
        end

        it "warns when using the short token" do
          expect do
            expect(described_class.for("version-newest")).to be_a Cask::CaskLoader::FromAPILoader
          end.to output(/version-newest was renamed to version-latest/).to_stderr
        end

        it "warns when using the full token" do
          expect do
            expect(described_class.for("homebrew/cask/version-newest")).to be_a Cask::CaskLoader::FromAPILoader
          end.to output(/version-newest was renamed to version-latest/).to_stderr
        end
      end
    end
  end
end
