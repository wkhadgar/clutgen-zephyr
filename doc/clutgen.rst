.. _external_module_clutgen:

CLUTGen
#######

Introduction
************

`CLUTGen <clutgen-zephyr_>`_ automates the creation of **Look-Up Tables** for embedded systems,
converting raw ADC readings into calibrated physical units such as temperature, pressure, or distance.

Given a set of calibration samples, CLUTGen fits an interpolation curve and generates a
production-ready ``.c``/``.h`` pair with the full LUT precomputed for every possible ADC reading.
At runtime, conversion is a single array index operation — O(1), no floating point, no branching.

This Zephyr module integrates CLUTGen directly into the west build system. LUT generation runs
at CMake configure time and the generated files are automatically linked into the application.

.. note::

   CLUTGen is licensed under the Apache License 2.0.


Usage with Zephyr
*****************

Requirements
============

* Python 3.10+
* ``numpy``, ``plotly`` (installed automatically via ``west packages``)


Installation
============

Declare the module in your workspace manifest, or pull it in via a submanifest.

For example, create ``zephyrproject/zephyr/submanifests/clutgen.yaml`` with the following content:

.. code-block:: yaml

   manifest:
     projects:
       - name: clutgen
         url: https://github.com/wkhadgar/clutgen-zephyr
         revision: zephyr
         path: modules/clutgen
         submodules: true

Then update the workspace and install Python dependencies into the west venv:

.. code-block:: sh

   west update
   west packages pip --install


CMake Integration
=================

In your application ``CMakeLists.txt``, call ``clutgen_add_luts`` with the paths to your
calibration TOML files:

.. code-block:: cmake

   clutgen_add_luts(
       TOMLS
           ${CMAKE_CURRENT_SOURCE_DIR}/calibration/temperature.toml
           ${CMAKE_CURRENT_SOURCE_DIR}/calibration/pressure.toml
   )

``clutgen_add_luts`` accepts the following parameters:

.. list-table::
   :header-rows: 1
   :widths: 15 10 20 55

   * - Parameter
     - Required
     - Default
     - Description
   * - ``TOMLS``
     - Yes
     - —
     - One or more paths to ``.toml`` calibration config files
   * - ``NAME``
     - No
     - ``lookup_tables``
     - Base name for the generated ``.c``/``.h`` files
   * - ``TARGET``
     - No
     - ``app``
     - CMake target to attach the generated sources to

Example with all parameters:

.. code-block:: cmake

   clutgen_add_luts(
       NAME sensor_luts
       TARGET app
       TOMLS
           ${CMAKE_CURRENT_SOURCE_DIR}/calibration/temperature.toml
           ${CMAKE_CURRENT_SOURCE_DIR}/calibration/pressure.toml
   )

LUT generation runs automatically when CMake configures the project. The generated files are
placed in the build directory and linked into the application automatically.

.. note::

   CLUTGen re-runs whenever a registered TOML file changes. CSV changes alone do not trigger
   reconfiguration — touch the corresponding TOML or run ``west build -p`` to force it.


Using the Generated LUTs
=========================

Each configured sensor produces an array named ``<n>_lut``, where ``n`` is the ``name`` field
defined in its TOML. Include the generated header and use the array directly:

.. code-block:: c

   #include "lookup_tables.h"  /* or your custom NAME.h */

   int val = temp_sensor_lut[adc_reading];

The ADC reading is used directly as the array index, so lookup is O(1) with no branching.


Exploring Interpolation Methods
================================

Before committing to an interpolation method in the TOML, use the interactive preview target
to compare all available methods visually:

.. code-block:: sh

   west build -t clutgen_plot

This opens an interactive figure in the browser showing all interpolation methods overlaid
against the calibration points for each configured sensor.

.. figure:: img/clutgen_plot_overview.png
   :align: center
   :alt: CLUTGen interactive preview showing all interpolation methods overlaid

   CLUTGen preview — all interpolation methods overlaid against calibration points.

When multiple sensors are configured, a dropdown allows switching between them:

.. figure:: img/clutgen_plot_multisensor.png
   :align: center
   :alt: CLUTGen preview with sensor selector dropdown

   CLUTGen preview — sensor selector dropdown for multi-sensor configurations.

You can focus on selected interpolations, zoom into regions, and see details hovering the
mouse over the plots to compare methods and have a secure choice:

.. figure:: img/clutgen_plot_interaction.png
   :align: center
   :alt: CLUTGen preview with hidden methods and focused region

   CLUTGen preview — interactive view changes for better method analysis.



TOML Configuration
==================

Each sensor requires a TOML configuration file and a CSV with its calibration samples.

**CSV schema:**

.. code-block:: text

   raw,calibration

Where ``raw`` is the ADC reading and ``calibration`` is the expected output value at that reading.

**TOML schema:**

.. code-block:: toml

   name = "temp_sensor"                # C identifier — used as <n>_lut in generated code
   description = "ambient temperature" # Used in Doxygen comments and plot titles
   table_resolution_bits = 12          # ADC resolution in bits (e.g., 12 → 4096 entries)
   lut_type = "int16_t"                # C type for the generated array

   samples_csv = "./data/temperature_samples.csv"  # Relative to this file, or absolute

   # Optional
   interpolation = "polynomial"        # Overrides the default interpolation method for this LUT

Interpolation Methods
---------------------

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Value
     - Description
   * - ``linear``
     - Linear interpolation between calibration points. Default.
   * - ``splines``
     - Cubic spline interpolation; smooth transitions between points.
   * - ``polynomial``
     - Best-fit polynomial up to degree 7; prone to oscillation with sparse data.
   * - ``piecewise``
     - Zero-order hold; constant value between points, step-like output.
   * - ``idw``
     - Inverse Distance Weighting; weighted average of all known points.


Reference
*********

- `CLUTGen Zephyr module <clutgen-zephyr_>`_
- `CLUTGen CLI tool <clutgen-cli_>`_
- `Zephyr Module System <zephyr-modules_>`_


.. _clutgen-zephyr: https://github.com/wkhadgar/clutgen-zephyr

.. _clutgen-cli: https://github.com/wkhadgar/clutgen

.. _zephyr-modules: https://docs.zephyrproject.org/latest/develop/modules.html
