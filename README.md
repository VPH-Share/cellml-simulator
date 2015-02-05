## CellML Simulator Webservice

#### Firewall Configuration

To be able to access the the server from external clients, certain port redirections and service endpoints need to be configured.

##### Security Groups (VPH-Share Port Redirections)

<table>
<thead>
<tr>
<th>Name    </th>
<th> Type </th>
<th> Port </th>
<th> Source    </th>
<th> Notes </th>
</tr>
</thead>
<tbody>
<tr>
<td>web </td>
<td> TCP  </td>
<td> 8080 </td>
<td> 0.0.0.0/0 </td>
<td>       </td>
</tr>
</tbody>
</table>

##### VPH-Share Endpoints

<table>
<thead>
<tr>
<th>Type         </th>
<th> Invocation Path       </th>
<th> Port      </th>
<th> WS/REST Descriptor</th>
</tr>
</thead>
<tbody>
<tr>
<td>soap         </td>
<td> /  </td>
<td> web(8080) </td>
<td> /?wsdl</td>
</tr>
</tbody>
</table>

**Note:** Ensure you insert the `WSDL` as a text string into the optional **WS/REST Descriptor** fields.
