describe Kumogata::Crypt do
  it 'encrypt string' do
    encrypted =  Kumogata::Crypt.encrypt("my_password", "jugem jugem")
    decrypted =  Kumogata::Crypt.decrypt("my_password", encrypted)
    expect(decrypted).to eq("jugem jugem")
  end

  it 'encrypt long string' do
    encrypted =  Kumogata::Crypt.encrypt("my_password", "jugem jugem" * 10240)
    decrypted =  Kumogata::Crypt.decrypt("my_password", encrypted)
    expect(decrypted).to eq("jugem jugem" * 10240)
  end
end
