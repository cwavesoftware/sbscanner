# WARNING: This file was automatically generated. You should avoid editing it.
# If you run pynixify again, the file will be either overwritten or
# deleted, and you will lose the changes you made to it.

{ buildPythonPackage
, fetchPypi
, lib
}:

buildPythonPackage rec {
  pname =
    "bidict";
  version =
    "0.21.4";

  src =
    fetchPypi {
      inherit
        pname
        version;
      sha256 =
        "0vwz0xd9vr2l9j2alx1lipbxrkkwxbllnfq7ys58kppqwvxlzj22";
    };

  # TODO FIXME
  doCheck =
    false;

  meta =
    with lib; {
      description =
        "The bidirectional mapping library for Python.";
      homepage =
        "https://bidict.readthedocs.io";
    };
}
