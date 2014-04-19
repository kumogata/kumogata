describe Kumogata::Utils do
  it 'should stringify the hash' do
    hash = {
      :foo => {
        'bar' => ['1', 2, 3],
        'zoo' => :value,
      },
      12 => :value2
    }

    expect(Kumogata::Utils.stringify(hash)).to eq(
      {
        'foo' => {
          'bar' => ['1', '2', '3'],
          'zoo' => 'value',
        },
        '12' => 'value2'
      }
    )
  end
end
