import os
import emissary
import soaplib
from soaplib.core.service import soap, rpc, DefinitionBase
from soaplib.core.model.primitive import String, Integer
from soaplib.core.model.clazz import ClassModel
from soaplib.core.server import wsgi


CMD_STR = "vendors/CSim-0.4.3-Linux/bin/csim {CELLML_MODEL} | tee {OUTPUT_FILE_PATH}"

class SimulatorResponse(ClassModel):
    """Response object holds the commandline execution response"""
    statuscode = Integer
    command = String
    stdout = String
    stderr = String
    cwd = String

    output_file_path = String

    def __init__(self, command=None):
        self.command = command
        self.cwd = '.'
        self.statuscode = 0
        self.stdout = ""
        self.stderr = "Error: I'm sorry I cannot do that, Dave!"

def create_response(out):
    r = SimulatorResponse(' '.join(out.command))
    r.statuscode = out.status_code
    r.stdout = out.std_out
    r.stderr = out.std_err
    return r

class CellMLSimulator(DefinitionBase):
    @soap(String, String, _returns=SimulatorResponse)
    def simulate(self, cellml_model, output_file_path):
        command = CMD_STR.format(CELLML_MODEL=cellml_model,
                                 OUTPUT_FILE_PATH=output_file_path)
        try:
            out = emissary.envoy.run(command)
            r = create_response(out)
            r.output_file_path = output_file_path
            return r
        except OSError, e:
            r = SimulatorResponse(command)
            r.statuscode = e.errno
            return e.strerror
        return r

soap_app = soaplib.core.Application([CellMLSimulator], 'cellml',
                                    name='CellMLSimulator')
application = wsgi.Application(soap_app)

if __name__=='__main__':
    try:
        from wsgiref.simple_server import make_server
        server = make_server(host='0.0.0.0', port=8080, app=application)
        server.serve_forever()
    except ImportError:
        print "Error: example server code requires Python >= 2.5"
