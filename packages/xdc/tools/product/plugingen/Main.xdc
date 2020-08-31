/*
 *  Copyright 2020 by Texas Instruments Incorporated.
 *
 */

/*!
 *  ======== Main ========
 *  Command-line tool for generating eclipse plugins for RTSC content
 *
 *  The `plugingen` tool allows RTSC content producers to
 *  create eclipse plugins that allows their content to be
 *  integrated in the CCS environment. As input, the tool requires
 *  @p(blist)
 *      - a RTSC module implementing {@link xdc.tools.product.IProduct}
 *  @p
 *  Refer to {@link ./doc-files/ExampleProduct.xdc ExampleProduct}
 *  for an implementation of {@link xdc.tools.product.IProduct IProduct}.
 *
 *  The tool may also be used to generate starter examples that will showup
 *  in the new project wizard. This is accomplished by implementing
 *  {@link xdc.tools.product.IProductTemplate IProductTemplate} and setting
 *  the {@link xdc.tools.product.IProduct#templateModule templateModule}
 *  configuration parameter of the {@link xdc.tools.product.IProduct IProduct}
 *  implementation to the name of the implementation module.
 *  Refer to {@link ./doc-files/Examples.xdc Examples}
 *  for a sample implementation of {@link
 *  xdc.tools.product.IProductTemplate IProductTemplate}.
 *
 *  The XGCONF product view maybe developed by implementing
 *  {@link xdc.tools.product.IProductView IProductView} and setting
 *  the {@link xdc.tools.product.IProduct#productViewModule productViewModule}
 *  configuration parameter of the {@link xdc.tools.product.IProduct IProduct}
 *  implementation to the name of the implementation module.
 *  Refer to {@link ./doc-files/ProductView.xdc ProductView.xdc} and
 *  {@link ./doc-files/ProductView.xs ProductView.xs}
 *  for a sample implementation of {@link
 *  xdc.tools.product.IProductView IProductView}.
 *
 *  The tool operates on a product that is either specified by the `-p`
 *  option or is present in the folder from which the tool is executed.
 *  The tool will create the plugin in a sub-folder named `eclipse`
 *  in the output directory specified with `-o` option. If the `-o`
 *  option is not specified the plugin is created in the product root
 *  directory.
 *
 *  @a(Example)
 *  @p(code)
 *      xs xdc.tools.product.plugingen 
 *                      -p exampleprod_1_0_0_00
 *                      -m xdc.tools.product.plugingen.examples.ExampleProduct
 *  @p
 */
metaonly module Main inherits xdc.tools.ICmd
{
    override config String usage[] = [
        '[-p product_root_directory]',
        ' -m module',
        '[-o outdir]',
        '[-f pluginFragment]'
    ];

instance:

    /*!
     *  ======== productDir ========
     *  Product root directory
     *
     *  This option names the product root directory that is used by the
     *  tool to generate the plugin.  For example, its declared repositories
     *  are added to the package path and are searched for contributed
     *  platforms.
     *
     *  If the '-o' option is not specified, the tool generates the plugin
     *  in a sub-directory named `eclipse` in the product root directory.
     *
     *  If this option is not specified, the product root directory is
     *  assumed to be `./`.
     *
     */
    @CommandOption("p")
    config String productDir = "./";

    /*!
     *  ======== productModule ========
     *  Input description of the plug-in to be specified
     *
     *  This required option names a module that implements
     *  `{@link xdc.tools.product.IProduct}`.
     */
    @CommandOption("m")
    config String productModule;

    /*!
     *  ======== outputDir ========
     *  Output directory in which the plugin will be generated.
     *
     *  This option names the directory in which the plugin
     *  will be generated in a sub-directory named `eclipse`.
     *  If this option is not specified the tool will generate
     *  the plugin in the product root directory specified with
     *  the '-p' option.
     */
    @CommandOption("o")
    config String outputDir = null;

    /*!
     *  ======== pluginFragment ========
     *  Text file containing plugin fragment
     *
     *  This option names the text file containing a plugin fragment.
     *  This allows users to contribute extensions to the UI plugins
     *  generated by the tool.
     *
     *  The tool does not perform syntax checking of the contributed
     *  fragment. Users need to ensure the correctness of the
     *  contributed fragment. Note that syntactically incorrect
     *  fragments can disable the plugin completely in the eclipse
     *  platform.
     */
    @CommandOption("f")
    config String pluginFragment = null;

    /*!
     *  ======== generationFormat ========
     *  Plugin generation format
     */
    @CommandOption("generation_format")
    config String generationFormat = null;

    /*!
     *  ======== suppress_product_type_info ========
     *  This Option is now removed from PluginGen.
     *  We shall throw an error to flag this change to users.
     *
     *  Suppress generation of product type information
     *
     *  This option generates eclipse plugin without the product
     *  type information. Should only be invoked to generate plugins
     *  whose product type information was hard coded into CCS 4.x prior
     *  to the creation of this tool.
     *
     *  This option should not be used by _any_ new products.
     */
    @CommandOption("suppress_product_type_info")
    config Bool suppressProductTypeInfo = false;

    /*!
     *  ======== dynamic_toc ========
     *  @_nodoc
     *
     *  This switch allows us to enable the new (to 3.30) dynamic TOC provider
     *  which can read TOC files that are _not_ in any of the signed plugins.
     *  Which means we can completely encapsulate the docs in a product's
     *  directories and there is no possibility of using a TOC that doesn't
     *  match the docs provided.
     *
     *  This option should only be used for products that will only be used
     *  with versions of XDCtools 3.30 or later (unless we backport this
     *  provider to 3.26, for example).
     *
     *  Someday we may ignore this switch as default to using dynamic_toc.
     *  But for now (3.30), dynamic_toc is only used by xdctools itself.
     */
    @CommandOption("dynamic_toc")
    config Bool dynamicToc = false;

    /*!
     *  ======== run ========
     */
    override Any run(xdc.tools.Cmdr.Instance cmdr, String args[]);
}
/*
 *  @(#) xdc.tools.product.plugingen; 1, 0, 0,0; 4-14-2020 17:01:50; /db/ztree/library/trees/xdctools/xdctools-h04/src/
 */

