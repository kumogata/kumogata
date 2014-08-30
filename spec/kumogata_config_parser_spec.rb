describe Kumogata::ConfigParser do
  subject { Kumogata::ConfigParser.new }

  it 'parse aws/config' do
    content = <<-EOS
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
aws_security_token = texample123324

[profile2]
aws_access_key_id = xAKIAIOSFODNN7EXAMPLE
aws_secret_access_key = xwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
aws_security_token = xtexample123324

[profile profile3]
aws_access_key_id = xAKIAIOSFODNN7EXAMPLE
aws_secret_access_key = xwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
aws_security_token = xtexample123324

[invalid]
    EOS

    tempfile(content) do |config|
      subject.path = config.path
      subject.parse!

      expect(subject[:default]).to eq(
        'aws_access_key_id' => 'AKIAIOSFODNN7EXAMPLE',
        'aws_secret_access_key' => 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
        'aws_security_token' => 'texample123324',
      )

      expect(subject['profile2']).to eq(
        'aws_access_key_id' => 'xAKIAIOSFODNN7EXAMPLE',
        'aws_secret_access_key' => 'xwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
        'aws_security_token' => 'xtexample123324',
      )

      expect(subject['profile3']).to eq(
        'aws_access_key_id' => 'xAKIAIOSFODNN7EXAMPLE',
        'aws_secret_access_key' => 'xwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
        'aws_security_token' => 'xtexample123324',
      )

      expect(subject['invalid']).to be_nil
    end
  end
end
