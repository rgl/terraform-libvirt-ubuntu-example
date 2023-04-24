<!--
    This customizes a libvirt domain xml.
    NB You can manually create a domain and them find the resulting domain xml at /etc/libvirt/qemu/*.xml.
    NB You can test this transformation with, e.g.:
        sudo xsltproc libvirt-domain.xsl /etc/libvirt/qemu/example.xml | sudo diff -u /etc/libvirt/qemu/example.xml - | vim -
    See https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/examples/v0.12/xslt/nicmodel.xsl
    See https://libvirt.org/formatdomain.html
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" omit-xml-declaration="yes" indent="yes"/>
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="/domain/devices/disk[@device='cdrom']/target/@bus">
    <xsl:attribute name="bus">
      <xsl:value-of select="'scsi'"/>
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="/domain/devices">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
      <channel type="spicevmc">
        <target type="virtio" name="com.redhat.spice.0"/>
        <address type="virtio-serial" controller="0" bus="0" port="2"/>
      </channel>
      <!--
      <input type="tablet" bus="usb">
        <address type="usb" bus="0" port="1"/>
      </input>
      -->
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
