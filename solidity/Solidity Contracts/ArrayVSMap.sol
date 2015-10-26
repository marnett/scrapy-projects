contract ArrayVSMap {
  function addToMap(bytes16 c) {
    testMapping[testMappingCount++] = c;
  }

  function addToArr(bytes16 c) {
    testArr[testArr.length++] = c;
  }

  function addToArrFixed(bytes16 c) {
    testArrFixed[testArrFixedCount++] = c;
  }

  function addTo256Map(bytes16 c) {
    test256Mapping[test256MappingCount++] = c;
  }

  function addTo64Map(bytes16 c) {
    test64Mapping[test64MappingCount++] = c;
  }

  function addTo48Map(bytes16 c) {
    test48Mapping[test48MappingCount++] = c;
  }

  function addTo40Map(bytes16 c) {
    test40Mapping[test40MappingCount++] = c;
  }

  function addTo32Map(bytes16 c) {
    test32Mapping[test32MappingCount++] = c;
  }

  function addTo24Map(bytes16 c) {
    test24Mapping[test24MappingCount++] = c;
  }

  function addTo16Map(bytes16 c) {
    test16Mapping[test16MappingCount++] = c;
  }

  function addTo8Map(bytes16 c) {
    test8Mapping[test8MappingCount++] = c;
  }

  bytes16[] public testArr;
  bytes16[10000] public testArrFixed;
  uint16 public testArrFixedCount;

  mapping (uint => bytes16) public testMapping;

  mapping (uint256 => bytes16) public test256Mapping;
  mapping (uint64 => bytes16) public test64Mapping;
  mapping (uint48 => bytes16) public test48Mapping;
  mapping (uint40 => bytes16) public test40Mapping;
  mapping (uint32 => bytes16) public test32Mapping;
  mapping (uint24 => bytes16) public test24Mapping;
  mapping (uint16 => bytes16) public test16Mapping;
  mapping (uint8 => bytes16) public test8Mapping;

  uint256 public test256MappingCount;
  uint64 public test64MappingCount;
  uint48 public test48MappingCount;
  uint40 public test40MappingCount;
  uint32 public test32MappingCount;
  uint24 public test24MappingCount;
  uint16 public test16MappingCount;
  uint8 public test8MappingCount;
  uint public testMappingCount;
}
