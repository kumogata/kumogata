describe 'Kumogata::Client#diff' do
  let(:drupal_single_instance_template) do
    path = File.expand_path('../Drupal_Single_Instance.template', __FILE__)
    open(path) {|f| f.read }
  end

  let(:drupal_single_instance_template_rb) do
    path = File.expand_path('../Drupal_Single_Instance.template.rb', __FILE__)
    open(path) {|f| f.read }
  end

  it 'compare templates logically' do
    json_template = drupal_single_instance_template
    json_template.sub!('localhost', '127.0.0.1')
    json_template.sub!('"ToPort": "80"', '"ToPort": "8080"')

    tempfile(json_template, '.templates') do |js|
      tempfile(drupal_single_instance_template_rb, '.rb') do |rb|
        diff = ruby_template = run_client(:diff, :arguments => [js.path, rb.path], :options => {:color => false})
        diff = diff.split(/\n/).slice(2..-1).join("\n")

        expect(diff).to eq((<<-EOS).chomp)
@@ -257,7 +257,7 @@
                       {
                         "Ref": "DBUsername"
                       },
-                      "'@'127.0.0.1' IDENTIFIED BY '",
+                      "'@'localhost' IDENTIFIED BY '",
                       {
                         "Ref": "DBPassword"
                       },
        EOS
      end
    end
  end
end
